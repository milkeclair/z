import { SpecialCharacters } from '../../../character';
import { advance, current, eof, startsWith } from '../../../cursor';
import type { Cursor } from '../../../cursor';
import { scan } from '../../../scan';
import type { ReadResult } from '../result';
import {
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

type QuotedState = {
  readonly cursor: Cursor;
  readonly text: string;
  readonly closed: boolean;
};

function readQuotedDone(state: QuotedState): boolean {
  return state.closed || eof(state.cursor);
}

function readQuotedStep({
  definition,
  state,
}: {
  readonly definition: QuoteDefinition;
  readonly state: QuotedState;
}): QuotedState {
  const result = advance(state.cursor);
  const nextText = state.text + result.value;

  if (
    definition.escapeBackslash &&
    result.value === SpecialCharacters.backslash &&
    !eof(result.cursor)
  ) {
    const escaped = advance(result.cursor);

    return {
      cursor: escaped.cursor,
      text: nextText + escaped.value,
      closed: false,
    };
  } else if (result.value === definition.end) {
    return {
      cursor: result.cursor,
      text: nextText,
      closed: true,
    };
  } else {
    return {
      cursor: result.cursor,
      text: nextText,
      closed: false,
    };
  }
}

function readQuoted(cursor: Cursor, definition: QuoteDefinition): ReadResult<QuoteReadValue> {
  const start = advance(cursor, definition.start.length);
  const result = scan({
    state: {
      cursor: start.cursor,
      text: start.value,
      closed: false,
    },
    done: readQuotedDone,
    step: (state: QuotedState) => readQuotedStep({ definition, state }),
  });

  return {
    value: {
      text: result.text,
      closed: result.closed,
      quoteKind: definition.quoteKind,
    },
    cursor: result.cursor,
  };
}

export function readQuote(cursor: Cursor): ReadResult<QuoteReadValue> | null {
  if (startsWith(cursor, DollarSingleQuoteDefinition.start)) {
    return readQuoted(cursor, DollarSingleQuoteDefinition);
  } else if (current(cursor) === SingleQuoteDefinition.start) {
    return readQuoted(cursor, SingleQuoteDefinition);
  } else if (current(cursor) === DoubleQuoteDefinition.start) {
    return readQuoted(cursor, DoubleQuoteDefinition);
  } else {
    return null;
  }
}
