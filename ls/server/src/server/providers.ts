import type { Connection } from 'vscode-languageserver/node';
import { zSemanticTokens } from '../connection/semanticTokens';
import type { DiagnosticSnapshot } from '../diagnostics/snapshot';
import {
  validateTextDocument,
  workspaceDiagnostics,
  zCompletion,
  zCompletionResolve,
  zDefinition,
  zHover,
  zSignatureHelp,
} from '../main';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { DocumentDiagnosticReportKind, TextDocument, TextDocuments } from '../vscode_type';

type RequestState = {
  readonly snapshot: FunctionSnapshot;
  readonly diagnosticSnapshot: DiagnosticSnapshot;
  readonly showPrivateFunctions: boolean;
};

type LanguageFeatureContext = {
  readonly connection: Connection;
  readonly documents: TextDocuments<TextDocument>;
  readonly currentState: () => RequestState;
};

function registerCompletion({ connection, documents, currentState }: LanguageFeatureContext): void {
  connection.onCompletion((params) => {
    const { snapshot, diagnosticSnapshot, showPrivateFunctions } = currentState();

    return zCompletion({
      params,
      documents,
      snapshot,
      showPrivateFunctions,
      programs: diagnosticSnapshot.files.get(params.textDocument.uri)?.codePrograms,
    });
  });

  connection.onCompletionResolve((result) => {
    const { snapshot, diagnosticSnapshot } = currentState();
    const data: unknown = result.data;
    const uri =
      typeof data === 'object' && data !== null && 'uri' in data && typeof data.uri === 'string'
        ? data.uri
        : '';

    return zCompletionResolve(result, snapshot, diagnosticSnapshot.files.get(uri)?.codePrograms);
  });
}

function registerNavigation({ connection, documents, currentState }: LanguageFeatureContext): void {
  connection.onHover((params) => {
    const { snapshot, diagnosticSnapshot } = currentState();

    return zHover({
      params,
      documents,
      snapshot,
      programs: diagnosticSnapshot.files.get(params.textDocument.uri)?.codePrograms,
    });
  });

  connection.onSignatureHelp((params) => {
    const { snapshot, diagnosticSnapshot } = currentState();

    return zSignatureHelp({
      params,
      documents,
      snapshot,
      programs: diagnosticSnapshot.files.get(params.textDocument.uri)?.codePrograms,
    });
  });

  connection.onDefinition((params) => {
    const { snapshot, diagnosticSnapshot } = currentState();

    return zDefinition({
      params,
      documents,
      snapshot,
      programs: diagnosticSnapshot.files.get(params.textDocument.uri)?.codePrograms,
    });
  });
}

function registerColoring({ connection, documents, currentState }: LanguageFeatureContext): void {
  connection.languages.semanticTokens.on((params) => {
    const { diagnosticSnapshot } = currentState();
    const document = documents.get(params.textDocument.uri);
    const result = document
      ? zSemanticTokens({
          document,
          programs: diagnosticSnapshot.files.get(document.uri)?.codePrograms ?? [],
        })
      : { data: [] };

    return { data: [...result.data] };
  });
}

function registerDiagnostics({
  connection,
  documents,
  currentState,
}: LanguageFeatureContext): void {
  connection.languages.diagnostics.on((params) => {
    const { diagnosticSnapshot } = currentState();
    const document = documents.get(params.textDocument.uri);

    return {
      kind: DocumentDiagnosticReportKind.Full,
      resultId: document ? diagnosticSnapshot.files.get(document.uri)?.resultId : undefined,
      items: document
        ? validateTextDocument({ diagnostics: diagnosticSnapshot, textDocument: document })
        : [],
    };
  });

  connection.languages.diagnostics.onWorkspace((params) => {
    const { diagnosticSnapshot } = currentState();
    const report = workspaceDiagnostics({
      diagnostics: diagnosticSnapshot,
      previousResultIds: params.previousResultIds,
    });

    return { items: report.items.map((item) => ({ ...item, items: [...item.items] })) };
  });
}

export function registerLanguageFeatures(context: LanguageFeatureContext): void {
  registerCompletion(context);
  registerNavigation(context);
  registerColoring(context);
  registerDiagnostics(context);
}
