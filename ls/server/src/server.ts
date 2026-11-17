import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import type { PendingAnalysis } from './connection/analysis';
import { analysisDelay, queueAnalysis } from './connection/analysis';
import { projectRootFromSettings } from './connection/projectRoot';
import { startPeriodicRescan } from './connection/rescan';
import { emptyShellEnvironment, readShellEnvironment } from './diagnostics/environment';
import { createDiagnosticSnapshot, refreshDiagnosticSnapshot } from './diagnostics/snapshot';
import {
  createFunctionSnapshot,
  refreshFunctionSnapshot,
  zInitialize,
  zSettingsFromConfigurationNotification,
} from './main';
import { registerLanguageFeatures } from './server/providers';
import {
  createConnection,
  DidChangeWatchedFilesNotification,
  ProposedFeatures,
  TextDocument,
  TextDocuments,
} from './vscode_type';

function startServer(): void {
  const conn = createConnection(ProposedFeatures.all);
  const documents = new TextDocuments(TextDocument);
  let snapshot = createFunctionSnapshot();
  let diagnosticSnapshot = createDiagnosticSnapshot();
  let environment = emptyShellEnvironment();
  let projectRoot = '';
  let workspaceRoot = '';
  let showPrivateFunctions = false;
  let supportsRefresh = false;
  let supportsWatchRegistration = false;
  let watcherReady = false;
  let stopped = false;
  let stopRescan: (() => void) | undefined;
  let pendingAnalysis: PendingAnalysis | null = null;
  let analysisTimer: ReturnType<typeof setTimeout> | undefined;
  let diagnosticsTimer: ReturnType<typeof setTimeout> | undefined;

  function scheduleDiagnosticsRefresh(): void {
    if (!supportsRefresh) {
      return;
    }
    clearTimeout(diagnosticsTimer);
    diagnosticsTimer = setTimeout(() => {
      diagnosticsTimer = undefined;
      void conn.languages.diagnostics.refresh().catch((error: unknown) => {
        conn.console.warn('Diagnostic refresh failed: ' + String(error));
      });
    }, 500);
  }

  function refresh(root = projectRoot, changedPaths?: readonly string[]): void {
    const next = refreshFunctionSnapshot({
      projectRoot: root,
      documents,
      previous: snapshot,
      changedPaths: watcherReady ? changedPaths : undefined,
    });
    const nextDiagnostics = refreshDiagnosticSnapshot({
      snapshot: next,
      environment,
      previous: diagnosticSnapshot,
    });
    snapshot = next;
    diagnosticSnapshot = nextDiagnostics;
    projectRoot = root;
    scheduleDiagnosticsRefresh();
  }

  function flushAnalysis(): void {
    clearTimeout(analysisTimer);
    analysisTimer = undefined;
    if (!pendingAnalysis) {
      return;
    }
    refresh(projectRoot, pendingAnalysis.changedPaths);
    pendingAnalysis = null;
  }

  function scheduleAnalysis(changedPaths: readonly string[] | undefined): void {
    if (stopped) {
      return;
    }
    const now = performance.now();
    pendingAnalysis = queueAnalysis(pendingAnalysis, watcherReady ? changedPaths : undefined, now);
    clearTimeout(analysisTimer);
    analysisTimer = setTimeout(
      () => {
        try {
          flushAnalysis();
        } catch (error: unknown) {
          conn.console.error('Analysis refresh failed: ' + String(error));
        }
      },
      analysisDelay(pendingAnalysis, now),
    );
  }

  function refreshAll(root = projectRoot): void {
    clearTimeout(analysisTimer);
    analysisTimer = undefined;
    refresh(root);
    pendingAnalysis = null;
  }

  conn.onInitialize(async (params) => {
    const result = zInitialize(params);
    projectRoot = result.projectRoot;
    workspaceRoot = result.workspaceRoot;
    snapshot = result.snapshot;
    environment = await readShellEnvironment();
    if (environment.kind === 'unavailable') {
      conn.console.warn('Shell environment unavailable: ' + environment.reason);
    }
    diagnosticSnapshot = refreshDiagnosticSnapshot({ snapshot, environment });
    showPrivateFunctions = result.settings.completion.showPrivateFunctions;
    supportsRefresh = params.capabilities.workspace?.diagnostics?.refreshSupport === true;
    supportsWatchRegistration =
      params.capabilities.workspace?.didChangeWatchedFiles?.dynamicRegistration === true;
    return result.serverCapabilities;
  });

  conn.onInitialized(() => {
    if (stopped) {
      return;
    }
    stopRescan?.();
    stopRescan = startPeriodicRescan(
      () => {
        if (projectRoot) {
          refreshAll();
        }
      },
      (error) => conn.console.error('Periodic rescan failed: ' + String(error)),
    );
    if (supportsWatchRegistration) {
      void conn.client
        .register(DidChangeWatchedFilesNotification.type, {
          watchers: [{ globPattern: '**/*.zsh' }],
        })
        .then(() => {
          if (stopped) {
            return;
          }
          refreshAll();
          watcherReady = workspaceRoot !== '' && projectRoot === workspaceRoot;
        })
        .catch((error: unknown) => {
          conn.console.warn('File watcher registration failed: ' + String(error));
        });
    }
  });

  conn.onDidChangeConfiguration((params) => {
    const settings = zSettingsFromConfigurationNotification(params.settings);
    showPrivateFunctions = settings.completion.showPrivateFunctions;
    refreshAll(projectRootFromSettings(workspaceRoot, settings.zPath));
  });
  function filePaths(uris: readonly string[]): readonly string[] {
    return uris.flatMap((uri) => {
      try {
        return [fileURLToPath(uri)];
      } catch {
        return [];
      }
    });
  }

  conn.onDidChangeWatchedFiles((params) =>
    scheduleAnalysis(filePaths(params.changes.map((change) => change.uri))),
  );
  documents.onDidChangeContent(() => scheduleAnalysis([]));
  documents.onDidSave((event) => {
    scheduleAnalysis(filePaths([event.document.uri]));
    flushAnalysis();
  });
  documents.onDidClose((event) => {
    scheduleAnalysis(filePaths([event.document.uri]));
    flushAnalysis();
  });

  registerLanguageFeatures({
    connection: conn,
    documents,
    currentState() {
      flushAnalysis();
      return { snapshot, diagnosticSnapshot, showPrivateFunctions };
    },
  });

  conn.onShutdown(() => {
    stopped = true;
    stopRescan?.();
    stopRescan = undefined;
    pendingAnalysis = null;
    clearTimeout(analysisTimer);
    clearTimeout(diagnosticsTimer);
  });
  documents.listen(conn);
  conn.listen();
}

startServer();
