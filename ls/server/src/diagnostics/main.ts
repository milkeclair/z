import type { TextDocument } from '../vscode_type';
import type { Diagnostics } from './type';
import type { DiagnosticSnapshot } from './snapshot';

export function validateTextDocument({ diagnostics, textDocument }: {
  readonly diagnostics: DiagnosticSnapshot; readonly textDocument: TextDocument;
}): Diagnostics[] {
  const file = diagnostics.files.get(textDocument.uri);
  return file?.version === textDocument.version ? [...file.items] : [];
}
