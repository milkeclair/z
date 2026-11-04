import { SpecialCharacters } from '../character';
import { createCursor } from '../cursor';
import { eof, position } from '../cursor';
import type { LexerDiagnostic } from '../diagnostic';
import { scan } from '../scan';
import type { Token, TokenizeOptions } from '../token';
import { createToken } from '../token';
import { isWordBoundary } from './boundary';
import { Reader } from './reader';
import { readTokenizeStep } from './step';
import type { Cursor } from '../cursor';

export type TokenizeState = {
  readonly cursor: Cursor;
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
};

export type TokenizeResult = {
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
};

export function tokenize(input: string, options: TokenizeOptions = {}): TokenizeResult {
  const sourceFile = options.sourceFile ?? SpecialCharacters.empty;
  const cursor = createCursor(input);
  const reader = Reader({ sourceFile });
  const result = scan({
    state: {
      cursor,
      tokens: [],
      diagnostics: [],
    },
    done: (state: TokenizeState) => eof(state.cursor),
    step: (state: TokenizeState) =>
      readTokenizeStep({
        state,
        sourceFile,
        reader,
        isWordBoundary,
      }),
  });
  const end = position(result.cursor);

  return {
    tokens: [
      ...result.tokens,
      createToken({
        kind: 'eof',
        value: SpecialCharacters.empty,
        sourceFile,
        start: end,
        end,
      }),
    ],
    diagnostics: result.diagnostics,
  };
}
