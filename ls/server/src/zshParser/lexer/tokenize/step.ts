import type { OperatorDefinition } from '../character';
import { SpecialCharacters } from '../character';
import type { Cursor } from '../cursor';
import { advance, current, position } from '../cursor';
import { delimitedEnd, hereDocHeader } from '../delimiter';
import type { LexerDiagnostic } from '../diagnostic';
import type { Token } from '../token';
import { createToken } from '../token';
import type { LexicalContext } from './context';
import { advanceLexicalContext, isDollarOpen, isProcessOpen } from './context';
import { readHereDocuments } from './heredoc';
import type { TokenizeState } from './index';
import { findOperator, isContinuation, isHorizontalWhitespace, isNewline } from './predicate';
import { Reader } from './reader';
import type { ReadResult } from './reader/result';

type TokenReader = ReturnType<typeof Reader>;

type TokenizeStepValue = {
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
};

type TokenizeStepInput = {
  readonly state: TokenizeState;
  readonly sourceFile: string;
  readonly reader: TokenReader;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
};

type TokenReadResult = ReadResult<TokenizeStepValue>;

export function readTokenizeStep(input: TokenizeStepInput): TokenizeState {
  const { state, sourceFile } = input;
  const result = readNext(input);
  const context = state.context.readHereDocs
    ? {
        ...state.context,
        previous: result.value.tokens.at(-1) ?? state.context.previous,
        pendingHereDocs: [],
        awaitingHereDoc: null,
        readHereDocs: false,
      }
    : result.value.tokens.reduce(advanceLexicalContext, state.context);
  const closesContext = result.value.tokens.some(
    (token) => token.operatorKind === state.context.close,
  );
  const unclosed: readonly LexerDiagnostic[] = closesContext
    ? state.context.pendingHereDocs.map((request) => ({
        kind: 'unclosedHereDocument',
        message: 'Missing here-document delimiter ' + request.delimiter,
        sourceFile,
        range: { start: position(state.cursor), end: position(result.cursor) },
      }))
    : [];

  return {
    ...state,
    context,
    cursor: result.cursor,
    tokens: result.value.tokens,
    diagnostics: [...result.value.diagnostics, ...unclosed],
  };
}

function singleToken(result: ReadResult<Token>): TokenReadResult {
  return { cursor: result.cursor, value: { tokens: [result.value], diagnostics: [] } };
}

function wordToken(result: ReturnType<TokenReader['word']>): TokenReadResult {
  return {
    cursor: result.cursor,
    value: { tokens: [result.value.token], diagnostics: result.value.diagnostics },
  };
}

function lineToken(
  kind: 'continuation' | 'newline',
  cursor: Cursor,
  result: ReadResult<string>,
  sourceFile: string,
): TokenReadResult {
  const token = createToken({
    kind,
    value: result.value,
    sourceFile,
    start: position(cursor),
    end: position(result.cursor),
  });

  return { cursor: result.cursor, value: { tokens: [token], diagnostics: [] } };
}

function startsPatternParenthesis(cursor: Cursor, context: LexicalContext): boolean {
  const previous = context.previous;

  return (
    current(cursor) === '(' &&
    previous?.kind === 'word' &&
    previous.range.end.offset === position(cursor).offset &&
    !previous.value.endsWith('=') &&
    (previous.value.includes('*') ||
      previous.value.includes('?') ||
      cursor.text[position(cursor).offset + 1] === '#')
  );
}

function readNext({
  state,
  sourceFile,
  reader,
  isWordBoundary,
}: TokenizeStepInput): TokenReadResult {
  if (state.context.readHereDocs) {
    const result = readHereDocuments(state.cursor, state.context.pendingHereDocs, sourceFile);

    return {
      cursor: result.cursor,
      value: { tokens: result.tokens, diagnostics: result.diagnostics },
    };
  }

  const cursor = state.cursor;
  const start = position(cursor);
  const pendingHeader = state.context.awaitingHereDoc;
  const header = pendingHeader ? hereDocHeader(cursor.text, pendingHeader.operatorOffset) : null;

  if (
    header &&
    header.end > start.offset &&
    !isHorizontalWhitespace(current(cursor)) &&
    !isNewline(cursor) &&
    !isContinuation(cursor)
  ) {
    return wordToken(reader.word(cursor, (candidate) => position(candidate).offset >= header.end));
  }

  if (isContinuation(cursor)) {
    return lineToken('continuation', cursor, reader.continuation(cursor), sourceFile);
  }

  if (isNewline(cursor)) {
    return lineToken('newline', cursor, reader.newline(cursor), sourceFile);
  }

  if (isHorizontalWhitespace(current(cursor))) {
    return singleToken(reader.whitespace(cursor));
  }

  if (
    current(cursor) === SpecialCharacters.hash &&
    (state.context.kind === 'command' || state.context.kind === 'array')
  ) {
    return singleToken(reader.comment(cursor));
  }

  if (startsPatternParenthesis(cursor, state.context)) {
    const end = delimitedEnd(cursor.text, start.offset, 'patternParen');

    if (end !== null) {
      const result = advance(cursor, end - start.offset);

      return singleToken({
        cursor: result.cursor,
        value: createToken({
          kind: 'word',
          value: result.value,
          sourceFile,
          start,
          end: position(result.cursor),
        }),
      });
    }
  }

  return readWordOrOperator({ cursor, reader, isWordBoundary, context: state.context });
}

function operatorAt(cursor: Cursor, context: LexicalContext): OperatorDefinition | null {
  const found = findOperator(cursor);

  if (found?.kind === 'arithmeticEnd' && context.kind !== 'arithmetic') {
    return { value: ')', kind: 'rightParen' };
  }

  const arithmetic = context.kind === 'arithmetic' || context.kind === 'math';

  if (
    found?.kind === 'arithmeticStart' &&
    (isProcessOpen(context, position(cursor).offset) ||
      (arithmetic && !isDollarOpen(context, position(cursor).offset)))
  ) {
    return { value: '(', kind: 'leftParen' };
  }

  return found;
}

function readWordOrOperator({
  cursor,
  context,
  reader,
  isWordBoundary,
}: {
  readonly cursor: Cursor;
  readonly context: LexicalContext;
  readonly reader: TokenReader;
  readonly isWordBoundary: (cursor: Cursor) => boolean;
}): TokenReadResult {
  const operator = operatorAt(cursor, context);

  return operator
    ? singleToken(reader.operator(cursor, operator))
    : wordToken(reader.word(cursor, isWordBoundary));
}
