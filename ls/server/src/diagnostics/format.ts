import type { ZshFileHydration } from '../zshHydrator';
import { DiagnosticSeverity } from '../vscode_type';
import type { Diagnostics } from './type';

export function formatDiagnostics(file: ZshFileHydration): readonly Diagnostics[] {
  const text = file.tokens.map(token => token.value).join('');
  if (!text) return [];
  const lines = text.split('\n');
  const diagnostics: Diagnostics[] = [];
  let offset = 0;
  let tokenIndex = 0;
  for (const [lineIndex, physical] of lines.entries()) {
    const line = physical.endsWith('\r') ? physical.slice(0, -1) : physical;
    while (tokenIndex + 1 < file.tokens.length && file.tokens[tokenIndex].range.end.offset <= offset) tokenIndex += 1;
    const token = file.tokens[tokenIndex];
    const syntaxSpace = token?.kind === 'whitespace' || token?.kind === 'newline' || token?.kind === 'eof';
    const message = lineIndex === 0 && !line.trim() ? 'File starts with an empty line.' :
      line.length > 0 && !line.trim() ? 'Line contains only whitespace characters.' : null;
    if (message && syntaxSpace) diagnostics.push({ severity: DiagnosticSeverity.Warning,
      code: 'empty-line', range: { start: { line: lineIndex, character: 0 },
        end: { line: lineIndex, character: line.length } }, message, source: 'z-ls' });
    offset += physical.length + 1;
  }
  if (!text.endsWith('\n')) {
    const position = { line: file.ast.eof.range.start.line, character: file.ast.eof.range.start.character };
    diagnostics.push({ severity: DiagnosticSeverity.Warning, code: 'final-newline',
      range: { start: position, end: position }, message: 'File does not end with a newline.', source: 'z-ls' });
  }
  return diagnostics;
}
