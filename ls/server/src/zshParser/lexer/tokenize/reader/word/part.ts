import { SpecialCharacters } from '../../../character';
import { advance, current, eof, position } from '../../../cursor';
import type { Cursor } from '../../../cursor';
import type { SourcePosition } from '../../../token';
import { quoteKind } from '../../../token';
import { readQuote } from '../quote';
import { createUnclosedQuoteDiagnostic } from './diagnostic';
import { readBackslash } from './escape';
import type { WordState } from './state';

function readQuotedPart({
  sourceFile,
  state,
  quoteStart,
  quotedPart,
}: {
  readonly sourceFile: string;
  readonly state: WordState;
  readonly quoteStart: SourcePosition;
  readonly quotedPart: NonNullable<ReturnType<typeof readQuote>>;
}): WordState {
  const nextState: WordState = {
    cursor: quotedPart.cursor,
    accumulatedText: state.accumulatedText + quotedPart.value.text,
    quoted: true,
    tokenQuoteKind: quoteKind(state.tokenQuoteKind, quotedPart.value.quoteKind),
    diagnostics: state.diagnostics,
  };

  if (!quotedPart.value.closed) {
    return {
      ...nextState,
      diagnostics: [
        ...state.diagnostics,
        createUnclosedQuoteDiagnostic({
          sourceFile,
          start: quoteStart,
          end: position(quotedPart.cursor),
          quote: quotedPart.value.quoteKind,
        }),
      ],
    };
  } else {
    return nextState;
  }
}

export function readWordDone({
  isWordBoundary,
  state,
}: {
  readonly isWordBoundary: (cursor: Cursor) => boolean;
  readonly state: WordState;
}): boolean {
  return eof(state.cursor) || isWordBoundary(state.cursor);
}

export function readWordStep({
  sourceFile,
  state,
}: {
  readonly sourceFile: string;
  readonly state: WordState;
}): WordState {
  const quoteStart = position(state.cursor);
  const quotedPart = readQuote(state.cursor);

  if (quotedPart !== null) {
    return readQuotedPart({
      sourceFile,
      state,
      quoteStart,
      quotedPart,
    });
  } else if (current(state.cursor) === SpecialCharacters.backslash) {
    const result = readBackslash(state.cursor);

    return {
      cursor: result.cursor,
      accumulatedText: state.accumulatedText + result.value,
      quoted: true,
      tokenQuoteKind: quoteKind(state.tokenQuoteKind, 'backslash'),
      diagnostics: state.diagnostics,
    };
  } else {
    const result = advance(state.cursor);

    return {
      cursor: result.cursor,
      accumulatedText: state.accumulatedText + result.value,
      quoted: state.quoted,
      tokenQuoteKind: state.tokenQuoteKind,
      diagnostics: state.diagnostics,
    };
  }
}
