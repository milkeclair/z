import {
  createConnection,
  TextDocuments,
  ProposedFeatures,
  DocumentDiagnosticReportKind,
} from 'vscode-languageserver/node';
import { TextDocument } from 'vscode-languageserver-textdocument';
import {
  getZshFunctions,
  validateTextDocument,
  zInitialize,
  zCompletion,
  zCompletionResolve,
  zHover,
  zDefinition,
  Func,
} from './main';

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

documents.onDidOpen((_change) => {
  conn.languages.diagnostics.refresh();
});

documents.onDidChangeContent((_change) => {
  conn.languages.diagnostics.refresh();
});

documents.onDidSave((change) => {
  const uri = change.document.uri;

  if (uri.endsWith('.zsh')) {
    functions = getZshFunctions(projectRoot);
    conn.languages.diagnostics.refresh();
  }
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

documents.listen(conn);
conn.listen();
