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
import { projectRootFromSettings } from './connection/projectRoot';

function startServer(): void {
  const conn = createConnection(ProposedFeatures.all);
  const documents = new TextDocuments(TextDocument);
  let snapshot = createFunctionSnapshot();
  let projectRoot = '';
  let workspaceRoot = '';
  let showPrivateFunctions = false;
  let supportsRefresh = false;
  let supportsWatchRegistration = false;
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

  function refresh(root = projectRoot): void {
    const next = refreshFunctionSnapshot({ projectRoot: root, documents, previous: snapshot });
    snapshot = next;
    projectRoot = root;
    scheduleDiagnosticsRefresh();
  }

  conn.onInitialize((params) => {
    const result = zInitialize(params);
    projectRoot = result.projectRoot;
    workspaceRoot = result.workspaceRoot;
    snapshot = result.snapshot;
    showPrivateFunctions = result.settings.completion.showPrivateFunctions;
    supportsRefresh = params.capabilities.workspace?.diagnostics?.refreshSupport === true;
    supportsWatchRegistration = params.capabilities.workspace?.didChangeWatchedFiles?.dynamicRegistration === true;
    return result.serverCapabilities;
  });

  conn.onInitialized(() => {
    if (supportsWatchRegistration) {
      void conn.client.register(DidChangeWatchedFilesNotification.type, {
        watchers: [{ globPattern: '**/*.zsh' }],
      }).catch((error: unknown) => {
        conn.console.warn('File watcher registration failed: ' + String(error));
      });
    }
  });

  conn.onDidChangeConfiguration((params) => {
    const settings = zSettingsFromConfigurationNotification(params.settings);
    showPrivateFunctions = settings.completion.showPrivateFunctions;
    refresh(projectRootFromSettings(workspaceRoot, settings.zPath));
  });
  conn.onDidChangeWatchedFiles(() => refresh());
  documents.onDidChangeContent(() => refresh());
  documents.onDidSave(() => refresh());
  documents.onDidClose(() => refresh());

  conn.onCompletion((params) =>
    zCompletion({ params, documents, functions: snapshot.functions, showPrivateFunctions }));
  conn.onCompletionResolve((result) => zCompletionResolve(result, projectRoot, snapshot.functions));
  conn.onHover((params) =>
    zHover({ params, documents, functions: snapshot.functions, projectRoot }));
  conn.onSignatureHelp((params) =>
    zSignatureHelp({ params, documents, functions: snapshot.functions, projectRoot }));
  conn.onDefinition((params) =>
    zDefinition({ params, documents, functions: snapshot.functions, projectRoot }));

  conn.languages.diagnostics.on((params) => {
    const document = documents.get(params.textDocument.uri);
    return {
      kind: DocumentDiagnosticReportKind.Full,
      items: document ? validateTextDocument({ functions: snapshot.functions, textDocument: document }) : [],
    };
  });
  conn.languages.diagnostics.onWorkspace(() =>
    workspaceDiagnostics({ projectRoot, documents, functions: snapshot.functions }));

  conn.onShutdown(() => {
    clearTimeout(diagnosticsTimer);
  });
  documents.listen(conn);
  conn.listen();
}

startServer();
