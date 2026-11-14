import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import {
  createConnection, TextDocuments, TextDocument, ProposedFeatures,
  DocumentDiagnosticReportKind, DidChangeWatchedFilesNotification,
} from './vscode_type';
import {
  refreshFunctionSnapshot, createFunctionSnapshot,
  validateTextDocument, workspaceDiagnostics, zInitialize,
  zSettingsFromConfigurationNotification, zCompletion, zCompletionResolve,
  zHover, zDefinition, zSignatureHelp,
} from './main';
import { createDiagnosticSnapshot, refreshDiagnosticSnapshot } from './diagnostics/snapshot';
import { readShellEnvironment, emptyShellEnvironment } from './diagnostics/environment';
import { projectRootFromSettings } from './connection/projectRoot';
import { queueAnalysis, analysisDelay } from './connection/analysis';
import type { PendingAnalysis } from './connection/analysis';

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
  let pendingAnalysis: PendingAnalysis | null = null;
  let analysisTimer: ReturnType<typeof setTimeout> | undefined;
  let diagnosticsTimer: ReturnType<typeof setTimeout> | undefined;

  function scheduleDiagnosticsRefresh(): void {
    if (!supportsRefresh) return;
    clearTimeout(diagnosticsTimer);
    diagnosticsTimer = setTimeout(() => {
      diagnosticsTimer = undefined;
      void conn.languages.diagnostics.refresh().catch((error: unknown) => {
        conn.console.warn('Diagnostic refresh failed: ' + String(error));
      });
    }, 500);
  }

  function refresh(root = projectRoot, changedPaths?: readonly string[]): void {
    const next = refreshFunctionSnapshot({ projectRoot: root, documents, previous: snapshot,
      changedPaths: watcherReady ? changedPaths : undefined });
    const nextDiagnostics = refreshDiagnosticSnapshot({ snapshot: next, environment, previous: diagnosticSnapshot });
    snapshot = next;
    diagnosticSnapshot = nextDiagnostics;
    projectRoot = root;
    scheduleDiagnosticsRefresh();
  }

  function flushAnalysis(): void {
    clearTimeout(analysisTimer);
    analysisTimer = undefined;
    if (!pendingAnalysis) return;
    refresh(projectRoot, pendingAnalysis.changedPaths);
    pendingAnalysis = null;
  }

  function scheduleAnalysis(changedPaths: readonly string[] | undefined): void {
    if (stopped) return;
    const now = performance.now();
    pendingAnalysis = queueAnalysis(pendingAnalysis, watcherReady ? changedPaths : undefined, now);
    clearTimeout(analysisTimer);
    analysisTimer = setTimeout(() => {
      try { flushAnalysis(); }
      catch (error: unknown) { conn.console.error('Analysis refresh failed: ' + String(error)); }
    }, analysisDelay(pendingAnalysis, now));
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
    if (environment.kind === 'unavailable') conn.console.warn('Shell environment unavailable: ' + environment.reason);
    diagnosticSnapshot = refreshDiagnosticSnapshot({ snapshot, environment });
    showPrivateFunctions = result.settings.completion.showPrivateFunctions;
    supportsRefresh = params.capabilities.workspace?.diagnostics?.refreshSupport === true;
    supportsWatchRegistration = params.capabilities.workspace?.didChangeWatchedFiles?.dynamicRegistration === true;
    return result.serverCapabilities;
  });

  conn.onInitialized(() => {
    if (supportsWatchRegistration) {
      void conn.client.register(DidChangeWatchedFilesNotification.type, {
        watchers: [{ globPattern: '**/*.zsh' }],
      }).then(() => {
        if (stopped) return;
        refreshAll();
        watcherReady = workspaceRoot !== '' && projectRoot === workspaceRoot;
      }).catch((error: unknown) => {
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
    return uris.flatMap(uri => {
      try { return [fileURLToPath(uri)]; } catch { return []; }
    });
  }

  conn.onDidChangeWatchedFiles(params => scheduleAnalysis(filePaths(params.changes.map(change => change.uri))));
  documents.onDidChangeContent(() => scheduleAnalysis([]));
  documents.onDidSave(event => { scheduleAnalysis(filePaths([event.document.uri])); flushAnalysis(); });
  documents.onDidClose(event => { scheduleAnalysis(filePaths([event.document.uri])); flushAnalysis(); });

  conn.onCompletion((params) => {
    flushAnalysis();
    return zCompletion({ params, documents, snapshot, showPrivateFunctions });
  });
  conn.onCompletionResolve((result) => { flushAnalysis(); return zCompletionResolve(result, snapshot); });
  conn.onHover((params) => {
    flushAnalysis();
    return zHover({ params, documents, snapshot });
  });
  conn.onSignatureHelp((params) => {
    flushAnalysis();
    return zSignatureHelp({ params, documents, snapshot });
  });
  conn.onDefinition((params) => {
    flushAnalysis();
    return zDefinition({ params, documents, snapshot });
  });

  conn.languages.diagnostics.on((params) => {
    flushAnalysis();
    const document = documents.get(params.textDocument.uri);
    return {
      kind: DocumentDiagnosticReportKind.Full,
      resultId: document ? diagnosticSnapshot.files.get(document.uri)?.resultId : undefined,
      items: document ? validateTextDocument({ diagnostics: diagnosticSnapshot, textDocument: document }) : [],
    };
  });
  conn.languages.diagnostics.onWorkspace(params => {
    flushAnalysis();
    return workspaceDiagnostics({ diagnostics: diagnosticSnapshot, previousResultIds: params.previousResultIds });
  });

  conn.onShutdown(() => {
    stopped = true;
    pendingAnalysis = null;
    clearTimeout(analysisTimer);
    clearTimeout(diagnosticsTimer);
  });
  documents.listen(conn);
  conn.listen();
}

startServer();
