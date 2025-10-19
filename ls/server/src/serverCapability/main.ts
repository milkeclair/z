import { TextDocumentSyncKind, InitializeResult } from '../vscode_type';

export function serverCapability(): InitializeResult {
  return {
    capabilities: {
      textDocumentSync: {
        openClose: true,
        change: TextDocumentSyncKind.Incremental,
      },
      completionProvider: {
        resolveProvider: true,
        triggerCharacters: ['.', ' '],
      },
      hoverProvider: true,
      definitionProvider: true,
      diagnosticProvider: {
        interFileDependencies: true,
        workspaceDiagnostics: true,
      },
    },
  };
}
