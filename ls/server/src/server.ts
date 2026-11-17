import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import { analysisDelay, queueAnalysis, type PendingAnalysis } from './connection/analysis';
import { projectRootFromSettings } from './connection/projectRoot';
import { startPeriodicRescan } from './connection/rescan';
import {
  emptyShellEnvironment,
  readShellEnvironment,
  type ShellEnvironment,
} from './diagnostics/environment';
import {
  createDiagnosticSnapshot,
  refreshDiagnosticSnapshot,
  type DiagnosticSnapshot,
} from './diagnostics/snapshot';
import {
  createFunctionSnapshot,
  refreshFunctionSnapshot,
  zInitialize,
  zSettingsFromConfigurationNotification,
} from './main';
import type { FunctionSnapshot } from './refreshFunctions/main';
import { registerLanguageFeatures } from './server/providers';
import { createIOState } from './util/ioState';
import {
  createConnection,
  DidChangeWatchedFilesNotification,
  ProposedFeatures,
  TextDocument,
  TextDocuments,
} from './vscode_type';

type ServerState = {
  readonly snapshot: FunctionSnapshot;
  readonly diagnosticSnapshot: DiagnosticSnapshot;
  readonly environment: ShellEnvironment;
  readonly projectRoot: string;
  readonly workspaceRoot: string;
  readonly showPrivateFunctions: boolean;
  readonly supportsRefresh: boolean;
  readonly supportsWatchRegistration: boolean;
  readonly watcherReady: boolean;
  readonly stopped: boolean;
  readonly stopRescan: (() => void) | undefined;
  readonly pendingAnalysis: PendingAnalysis | null;
  readonly analysisTimer: ReturnType<typeof setTimeout> | undefined;
  readonly diagnosticsTimer: ReturnType<typeof setTimeout> | undefined;
};

function localFilePaths(uris: readonly string[]): readonly string[] {
  return uris.flatMap((uri) => {
    try {
      return [fileURLToPath(uri)];
    } catch {
      return [];
    }
  });
}

function startServer(): void {
  const connection = createConnection(ProposedFeatures.all);
  const documents = new TextDocuments(TextDocument);
  const state = createIOState<ServerState>({
    snapshot: createFunctionSnapshot(),
    diagnosticSnapshot: createDiagnosticSnapshot(),
    environment: emptyShellEnvironment(),
    projectRoot: '',
    workspaceRoot: '',
    showPrivateFunctions: false,
    supportsRefresh: false,
    supportsWatchRegistration: false,
    watcherReady: false,
    stopped: false,
    stopRescan: undefined,
    pendingAnalysis: null,
    analysisTimer: undefined,
    diagnosticsTimer: undefined,
  });

  function scheduleDiagnosticsRefresh(): void {
    const current = state.read();
    if (!current.supportsRefresh) {
      return;
    }
    clearTimeout(current.diagnosticsTimer);
    const timer = setTimeout(() => {
      state.update((previous) => ({ ...previous, diagnosticsTimer: undefined }));
      void connection.languages.diagnostics.refresh().catch((error: unknown) => {
        connection.console.warn('Diagnostic refresh failed: ' + String(error));
      });
    }, 500);
    state.update((previous) => ({ ...previous, diagnosticsTimer: timer }));
  }

  function refresh(root = state.read().projectRoot, changedPaths?: readonly string[]): void {
    const current = state.read();
    const snapshot = refreshFunctionSnapshot({
      projectRoot: root,
      documents,
      previous: current.snapshot,
      changedPaths: current.watcherReady ? changedPaths : undefined,
    });
    const diagnosticSnapshot = refreshDiagnosticSnapshot({
      snapshot,
      environment: current.environment,
      previous: current.diagnosticSnapshot,
    });
    state.replace({ ...current, snapshot, diagnosticSnapshot, projectRoot: root });
    scheduleDiagnosticsRefresh();
  }

  function flushAnalysis(): void {
    const current = state.read();
    clearTimeout(current.analysisTimer);
    state.update((previous) => ({ ...previous, analysisTimer: undefined }));
    if (!current.pendingAnalysis) {
      return;
    }
    refresh(current.projectRoot, current.pendingAnalysis.changedPaths);
    state.update((previous) => ({ ...previous, pendingAnalysis: null }));
  }

  function scheduleAnalysis(changedPaths: readonly string[] | undefined): void {
    const current = state.read();
    if (current.stopped) {
      return;
    }
    const now = performance.now();
    const pendingAnalysis = queueAnalysis(
      current.pendingAnalysis,
      current.watcherReady ? changedPaths : undefined,
      now,
    );
    clearTimeout(current.analysisTimer);
    const timer = setTimeout(
      () => {
        try {
          flushAnalysis();
        } catch (error: unknown) {
          connection.console.error('Analysis refresh failed: ' + String(error));
        }
      },
      analysisDelay(pendingAnalysis, now),
    );
    state.replace({ ...current, pendingAnalysis, analysisTimer: timer });
  }

  function refreshAll(root = state.read().projectRoot): void {
    clearTimeout(state.read().analysisTimer);
    state.update((previous) => ({ ...previous, analysisTimer: undefined }));
    refresh(root);
    state.update((previous) => ({ ...previous, pendingAnalysis: null }));
  }

  connection.onInitialize(async (params) => {
    const initialized = zInitialize(params);
    state.update((previous) => ({
      ...previous,
      projectRoot: initialized.projectRoot,
      workspaceRoot: initialized.workspaceRoot,
      snapshot: initialized.snapshot,
    }));
    const environment = await readShellEnvironment();
    if (environment.kind === 'unavailable') {
      connection.console.warn('Shell environment unavailable: ' + environment.reason);
    }
    const current = state.read();
    state.replace({
      ...current,
      environment,
      diagnosticSnapshot: refreshDiagnosticSnapshot({ snapshot: current.snapshot, environment }),
      showPrivateFunctions: initialized.settings.completion.showPrivateFunctions,
      supportsRefresh: params.capabilities.workspace?.diagnostics?.refreshSupport === true,
      supportsWatchRegistration:
        params.capabilities.workspace?.didChangeWatchedFiles?.dynamicRegistration === true,
    });
    return initialized.serverCapabilities;
  });

  connection.onInitialized(() => {
    const current = state.read();
    if (current.stopped) {
      return;
    }
    current.stopRescan?.();
    const stopRescan = startPeriodicRescan(
      () => {
        if (state.read().projectRoot) {
          refreshAll();
        }
      },
      (error) => connection.console.error('Periodic rescan failed: ' + String(error)),
    );
    state.update((previous) => ({ ...previous, stopRescan }));
    if (current.supportsWatchRegistration) {
      void connection.client
        .register(DidChangeWatchedFilesNotification.type, {
          watchers: [{ globPattern: '**/*.zsh' }],
        })
        .then(() => {
          if (state.read().stopped) {
            return;
          }
          refreshAll();
          state.update((previous) => ({
            ...previous,
            watcherReady:
              previous.workspaceRoot !== '' && previous.projectRoot === previous.workspaceRoot,
          }));
        })
        .catch((error: unknown) =>
          connection.console.warn('File watcher registration failed: ' + String(error)),
        );
    }
  });

  connection.onDidChangeConfiguration((params) => {
    const settings = zSettingsFromConfigurationNotification(params.settings);
    state.update((previous) => ({
      ...previous,
      showPrivateFunctions: settings.completion.showPrivateFunctions,
    }));
    refreshAll(projectRootFromSettings(state.read().workspaceRoot, settings.zPath));
  });
  connection.onDidChangeWatchedFiles((params) =>
    scheduleAnalysis(localFilePaths(params.changes.map((change) => change.uri))),
  );
  documents.onDidChangeContent(() => scheduleAnalysis([]));
  documents.onDidSave((event) => {
    scheduleAnalysis(localFilePaths([event.document.uri]));
    flushAnalysis();
  });
  documents.onDidClose((event) => {
    scheduleAnalysis(localFilePaths([event.document.uri]));
    flushAnalysis();
  });

  registerLanguageFeatures({
    connection,
    documents,
    currentState: () => {
      flushAnalysis();
      const { snapshot, diagnosticSnapshot, showPrivateFunctions } = state.read();
      return { snapshot, diagnosticSnapshot, showPrivateFunctions };
    },
  });

  connection.onShutdown(() => {
    const current = state.read();
    state.replace({ ...current, stopped: true, stopRescan: undefined, pendingAnalysis: null });
    current.stopRescan?.();
    clearTimeout(current.analysisTimer);
    clearTimeout(current.diagnosticsTimer);
  });
  documents.listen(connection);
  connection.listen();
}
startServer();
