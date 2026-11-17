import { codeTokenTypes } from '../connection/semanticTokens';
import { TextDocumentSyncKind, InitializeResult } from '../vscode_type';

export function serverCapability(): InitializeResult {
  return {
    capabilities: {
      textDocumentSync: {
        openClose: true,
        change: TextDocumentSyncKind.Incremental,
        save: true,
      },
      completionProvider: {
        resolveProvider: true,
        triggerCharacters: ['.'],
      },
      semanticTokensProvider: {
        legend: { tokenTypes: [...codeTokenTypes], tokenModifiers: [] },
        full: true,
      },
      hoverProvider: true,
      signatureHelpProvider: {
        triggerCharacters: [' '],
        retriggerCharacters: [' '],
      },
      definitionProvider: true,
      diagnosticProvider: {
        interFileDependencies: true,
        workspaceDiagnostics: true,
      },
    },
  };
}
