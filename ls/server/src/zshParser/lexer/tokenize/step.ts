import { delimitedEnd, hereDocHeader } from '../delimiter';
import { advance } from '../cursor';
import { readHereDocuments } from './heredoc';
import type { OperatorDefinition } from '../character';
import type { LexicalContext } from './context';
import { advanceLexicalContext, isDollarOpen, isProcessOpen } from './context';
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
    state,
    sourceFile,
    reader,
    isWordBoundary,
  });

  const context = state.context.readHereDocs
    ? { ...state.context, previous: result.value.tokens.at(-1) ?? state.context.previous, pendingHereDocs: [], awaitingHereDoc: null, readHereDocs: false }
    : result.value.tokens.reduce(advanceLexicalContext, state.context);
  const unclosed = result.value.tokens.some((token) => token.operatorKind === state.context.close)
    ? state.context.pendingHereDocs.map((request): LexerDiagnostic => ({
      kind: 'unclosedHereDocument', message: 'Missing here-document delimiter ' + request.delimiter,
      sourceFile, range: { start: position(state.cursor), end: position(result.cursor) },
    })) : [];
  return {
    ...state,
    context,
    cursor: result.cursor,
    tokens: result.value.tokens,
    diagnostics: [...result.value.diagnostics, ...unclosed],
  };
}

function readNext({
  state,
  sourceFile,
  reader,
  isWordBoundary,
}: {
  readonly state: TokenizeState;
  readonly sourceFile: string;
  readonly reader: ReturnType<typeof Reader>;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
}): ReadResult<TokenizeStepValue> {
  if (state.context.readHereDocs) {
    const result = readHereDocuments(state.cursor, state.context.pendingHereDocs, sourceFile);
    return { cursor: result.cursor, value: { tokens: result.tokens, diagnostics: result.diagnostics } };
  }
  const cursor = state.cursor;
  const start = position(cursor);

  const pendingHeader = state.context.awaitingHereDoc;
  const header = pendingHeader ? hereDocHeader(cursor.text, pendingHeader.operatorOffset) : null;
  if (header && header.end > start.offset && !isHorizontalWhitespace(current(cursor)) && !isNewline(cursor) && !isContinuation(cursor)) {
    const result = reader.word(cursor, (candidate) => position(candidate).offset >= header.end);
    return { cursor: result.cursor, value: { tokens: [result.value.token], diagnostics: result.value.diagnostics } };
  }

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
  } else if (current(cursor) === SpecialCharacters.hash && (state.context.kind === 'command' || state.context.kind === 'array')) {
    const result = reader.comment(cursor);

    return {
      cursor: result.cursor,
      value: {
        tokens: [result.value],
        diagnostics: [],
      },
    };
  } else if (current(cursor) === '(' && state.context.previous?.kind === 'word' &&
    state.context.previous.range.end.offset === start.offset && !state.context.previous.value.endsWith('=') &&
    (state.context.previous.value.includes('*') || state.context.previous.value.includes('?') || cursor.text[start.offset + 1] === '#')) {
    const end = delimitedEnd(cursor.text, start.offset, 'patternParen');
    if (end !== null) {
      const result = advance(cursor, end - start.offset);
      return { cursor: result.cursor, value: { tokens: [createToken({
        kind: 'word', value: result.value, sourceFile, start, end: position(result.cursor),
      })], diagnostics: [] } };
    }
    return readWordOrOperator({ cursor, reader, isWordBoundary, context: state.context });
  } else {
    return readWordOrOperator({
      context: state.context,
      cursor,
      reader,
      isWordBoundary,
    });
  }
}

function readWordOrOperator({
  cursor,
  context,
  reader,
  isWordBoundary,
}: {
  readonly cursor: Cursor;
  readonly context: LexicalContext;
  readonly reader: ReturnType<typeof Reader>;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
}): ReadResult<TokenizeStepValue> {
  const found = findOperator(cursor);
  const arithmetic = context.kind === 'arithmetic' || context.kind === 'math';
  const operator: OperatorDefinition | null = found?.kind === 'arithmeticEnd' && context.kind !== 'arithmetic'
    ? { value: ')', kind: 'rightParen' }
    : found?.kind === 'arithmeticStart' && (isProcessOpen(context, position(cursor).offset) || arithmetic && !isDollarOpen(context, position(cursor).offset)) ? { value: '(', kind: 'leftParen' } : found;

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
