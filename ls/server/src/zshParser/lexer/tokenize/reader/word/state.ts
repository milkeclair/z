import { SpecialCharacters } from '../../../character';
import type { Cursor } from '../../../cursor';
import type { LexerDiagnostic } from '../../../diagnostic';
import type { QuoteKind } from '../../../token';

export type WordState = {
  readonly cursor: Cursor;
  readonly accumulatedText: string;
  readonly quoted: boolean;
  readonly tokenQuoteKind: QuoteKind;
  readonly diagnostics: readonly LexerDiagnostic[];
};

export function initialWordState(cursor: Cursor): WordState {
  return {
    cursor,
    accumulatedText: SpecialCharacters.empty,
    quoted: false,
    tokenQuoteKind: 'none',
    diagnostics: [],
  };
}
