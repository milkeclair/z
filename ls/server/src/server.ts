import {
  createConnection,
  TextDocuments,
  TextDocument,
  ProposedFeatures,
  DocumentDiagnosticReportKind,
  DidChangeWatchedFilesNotification,
} from './vscode_type';
import {
  refreshFunctions,
  validateTextDocument,
  workspaceDiagnostics,
  zInitialize,
  zCompletion,
  zCompletionResolve,
  zHover,
  zDefinition,
  Func,
} from './main';
import { debounce } from './util/debounce';

const conn = createConnection(ProposedFeatures.all);
const documents = new TextDocuments(TextDocument);

let functions: Func[] = [];
let projectRoot = '';

conn.onInitialize((params) => {
  const result = zInitialize(params);
  projectRoot = result.projectRoot;
  functions = result.functions;

  return result.serverCapabilities;
});

conn.onInitialized(() => {
  conn.client.register(DidChangeWatchedFilesNotification.type, {
    watchers: [
      {
        globPattern: '**/*.zsh',
      },
    ],
  });
});

conn.onDidChangeWatchedFiles(() => {
  functions = refreshFunctions({ projectRoot, documents });
  conn.languages.diagnostics.refresh();
});

documents.onDidOpen(() => {
  functions = refreshFunctions({ projectRoot, documents });
  conn.languages.diagnostics.refresh();
});

const debouncedRefresh = debounce(() => {
  functions = refreshFunctions({ projectRoot, documents });
  conn.languages.diagnostics.refresh();
});

documents.onDidChangeContent(() => {
  debouncedRefresh();
});

documents.onDidSave(() => {
  functions = refreshFunctions({ projectRoot, documents });
  conn.languages.diagnostics.refresh();
});

documents.onDidClose(() => {
  functions = refreshFunctions({ projectRoot, documents });
  conn.languages.diagnostics.refresh();
});

conn.onCompletion((params) => {
  return zCompletion({ params, documents, functions });
});

conn.onCompletionResolve((result) => {
  return zCompletionResolve(result);
});

conn.onHover((params) => {
  return zHover({ params, documents, functions, projectRoot });
});

conn.onDefinition((params) => {
  return zDefinition({ params, documents, functions, projectRoot });
});

conn.languages.diagnostics.on((params) => {
  const document = documents.get(params.textDocument.uri);
  const hasDocument = document !== undefined;

  return {
    kind: DocumentDiagnosticReportKind.Full,
    items: hasDocument ? validateTextDocument({ functions, textDocument: document }) : [],
  };
});

conn.languages.diagnostics.onWorkspace(() => {
  return workspaceDiagnostics({ projectRoot, documents, functions });
});

documents.listen(conn);
conn.listen();
