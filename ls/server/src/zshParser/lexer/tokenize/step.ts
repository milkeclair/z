import { SpecialCharacters } from '../character';
import { current, position } from '../cursor';
import type { Cursor } from '../cursor';
import type { LexerDiagnostic } from '../diagnostic';
import type { Token } from '../token';
import { createToken } from '../token';
import { findOperator, isContinuation, isHorizontalWhitespace, isNewline } from './predicate';
import { Reader } from './reader';
import type { ReadResult } from './reader/result';
import type { TokenizeState } from './index';

type TokenizeStepValue = {
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
};

export function readTokenizeStep({
  state,
  sourceFile,
  reader,
  isWordBoundary,
}: {
  readonly state: TokenizeState;
  readonly sourceFile: string;
  readonly reader: ReturnType<typeof Reader>;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
}): TokenizeState {
  const result = readNext({
    cursor: state.cursor,
    sourceFile,
    reader,
    isWordBoundary,
  });

  return {
    cursor: result.cursor,
    tokens: [...state.tokens, ...result.value.tokens],
    diagnostics: [...state.diagnostics, ...result.value.diagnostics],
  };
}

function readNext({
  cursor,
  sourceFile,
  reader,
  isWordBoundary,
}: {
  readonly cursor: Cursor;
  readonly sourceFile: string;
  readonly reader: ReturnType<typeof Reader>;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
}): ReadResult<TokenizeStepValue> {
  const start = position(cursor);

  if (isContinuation(cursor)) {
    const result = reader.continuation(cursor);

    return {
      cursor: result.cursor,
      value: {
        tokens: [
          createToken({
            kind: 'continuation',
            value: result.value,
            sourceFile,
            start,
            end: position(result.cursor),
          }),
        ],
        diagnostics: [],
      },
    };
  } else if (isNewline(cursor)) {
    const result = reader.newline(cursor);

    return {
      cursor: result.cursor,
      value: {
        tokens: [
          createToken({
            kind: 'newline',
            value: result.value,
            sourceFile,
            start,
            end: position(result.cursor),
          }),
        ],
        diagnostics: [],
      },
    };
  } else if (isHorizontalWhitespace(current(cursor))) {
    const result = reader.whitespace(cursor);

    return {
      cursor: result.cursor,
      value: {
        tokens: [result.value],
        diagnostics: [],
      },
    };
  } else if (current(cursor) === SpecialCharacters.hash) {
    const result = reader.comment(cursor);

    return {
      cursor: result.cursor,
      value: {
        tokens: [result.value],
        diagnostics: [],
      },
    };
  } else {
    return readWordOrOperator({
      cursor,
      reader,
      isWordBoundary,
    });
  }
}

function readWordOrOperator({
  cursor,
  reader,
  isWordBoundary,
}: {
  readonly cursor: Cursor;
  readonly reader: ReturnType<typeof Reader>;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
}): ReadResult<TokenizeStepValue> {
  const operator = findOperator(cursor);

  if (operator) {
    const result = reader.operator(cursor, operator);

    return {
      cursor: result.cursor,
      value: {
        tokens: [result.value],
        diagnostics: [],
      },
    };
  } else {
    const result = reader.word(cursor, isWordBoundary);

    return {
      cursor: result.cursor,
      value: {
        tokens: [result.value.token],
        diagnostics: result.value.diagnostics,
      },
    };
  }
}
