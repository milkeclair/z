import { position } from '../../../cursor';
import type { Cursor } from '../../../cursor';
import type { LexerDiagnostic } from '../../../diagnostic';
import { scan } from '../../../scan';
import type { Token } from '../../../token';
import { createToken } from '../../../token';
import type { ReadResult } from '../result';
import { readWordStep, readWordDone } from './part';
import { initialWordState } from './state';
import type { WordState } from './state';

export type WordBoundary = (cursor: Cursor) => boolean;

type ReadWordContext = {
  readonly sourceFile: string;
  readonly cursor: Cursor;
  readonly isWordBoundary: WordBoundary;
};

type WordReadValue = {
  readonly token: Token;
  readonly diagnostics: readonly LexerDiagnostic[];
};

export function readWord({
  sourceFile,
  cursor,
  isWordBoundary,
}: ReadWordContext): ReadResult<WordReadValue> {
  const start = position(cursor);
  const result = scan({
    state: initialWordState(cursor),
    done: (state: WordState) => readWordDone({ isWordBoundary, state }),
    step: (state: WordState) => readWordStep({ sourceFile, state }),
  });

  return {
    value: {
      token: createToken({
        kind: 'word',
        value: result.accumulatedText,
        sourceFile,
        start,
        end: position(result.cursor),
        quoted: result.quoted,
        quoteKindValue: result.tokenQuoteKind,
      }),
      diagnostics: result.diagnostics,
    },
    cursor: result.cursor,
  };
}
