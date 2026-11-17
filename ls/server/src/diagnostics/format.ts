import { List } from 'immutable';
import { again, done, loop } from '../util/loop';
import { DiagnosticSeverity } from '../vscode_type';
import type { ZshFileHydration } from '../zshHydrator';
import type { Diagnostics } from './type';
export function formatDiagnostics(file: ZshFileHydration): readonly Diagnostics[] {
  const text = file.tokens.map((token) => token.value).join('');
  if (!text) {
    return [];
  }
  const scanned = text.split('\n').reduce(
    (state, physical, lineIndex) => {
      const line = physical.endsWith('\r') ? physical.slice(0, -1) : physical;
      const tokenIndex = loop(state.tokenIndex, (index) =>
        index + 1 < file.tokens.length && file.tokens[index].range.end.offset <= state.offset
          ? again(index + 1)
          : done(index),
      );
      const token = file.tokens[tokenIndex];
      const syntaxSpace =
        token?.kind === 'whitespace' || token?.kind === 'newline' || token?.kind === 'eof';
      const message =
        lineIndex === 0 && !line.trim()
          ? 'File starts with an empty line.'
          : line.length > 0 && !line.trim()
            ? 'Line contains only whitespace characters.'
            : null;
      const diagnostics =
        message && syntaxSpace
          ? state.diagnostics.push({
              severity: DiagnosticSeverity.Warning,
              code: 'empty-line',
              range: {
                start: { line: lineIndex, character: 0 },
                end: { line: lineIndex, character: line.length },
              },
              message,
              source: 'z-ls',
            })
          : state.diagnostics;
      return { offset: state.offset + physical.length + 1, tokenIndex, diagnostics };
    },
    { offset: 0, tokenIndex: 0, diagnostics: List<Diagnostics>() },
  );
  if (text.endsWith('\n')) {
    return scanned.diagnostics.toArray();
  }
  const position = {
    line: file.ast.eof.range.start.line,
    character: file.ast.eof.range.start.character,
  };
  return scanned.diagnostics
    .push({
      severity: DiagnosticSeverity.Warning,
      code: 'final-newline',
      range: { start: position, end: position },
      message: 'File does not end with a newline.',
      source: 'z-ls',
    })
    .toArray();
}
