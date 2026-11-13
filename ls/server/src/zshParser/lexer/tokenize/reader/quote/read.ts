import { SpecialCharacters } from '../../../character';
import { advance, current, startsWith } from '../../../cursor';
import type { Cursor } from '../../../cursor';
import { delimitedEnd } from '../../../delimiter';
import type { ReadResult } from '../result';
import {
  BacktickQuoteDefinition,
  DollarSingleQuoteDefinition,
  DoubleQuoteDefinition,
  SingleQuoteDefinition,
} from './definition';
import type { QuoteDefinition, QuoteReadKind } from './definition';

type QuotedValue = {
  readonly text: string;
  readonly closed: boolean;
};

type QuoteReadValue = QuotedValue & {
  readonly quoteKind: QuoteReadKind;
};

function readQuoted(cursor: Cursor, definition: QuoteDefinition): ReadResult<QuoteReadValue> {
  const end = delimitedEnd(cursor.text, cursor.position.offset, definition.quoteKind);
  const result = advance(cursor, (end ?? cursor.text.length) - cursor.position.offset);
  return {
    value: { text: result.value, closed: end !== null, quoteKind: definition.quoteKind },
    cursor: result.cursor,
  };
}

export function readQuote(cursor: Cursor): ReadResult<QuoteReadValue> | null {
  if (current(cursor) === BacktickQuoteDefinition.start) {
    return readQuoted(cursor, BacktickQuoteDefinition);
  } else if (startsWith(cursor, DollarSingleQuoteDefinition.start)) {
    return readQuoted(cursor, DollarSingleQuoteDefinition);
  } else if (current(cursor) === SingleQuoteDefinition.start) {
    return readQuoted(cursor, SingleQuoteDefinition);
  } else if (current(cursor) === DoubleQuoteDefinition.start) {
    return readQuoted(cursor, DoubleQuoteDefinition);
  } else {
    return null;
  }
}
