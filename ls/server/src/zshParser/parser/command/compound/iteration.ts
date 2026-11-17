import { appendItems, collectArray } from '../../../../util/collections';
import { again, done, loop } from '../../../../util/loop';
import type { ArithmeticExpansionNode, WordNode } from '../../../ast';
import { delimitedEnd } from '../../../lexer/delimiter';
import type { ParserContext } from '../../context';
import { rangeFromTokens } from '../../range';
import type { NodeResult, ParseState } from '../../state';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipInlineTrivia,
  skipTrivia,
  tokenSlice,
} from '../../state';
import { readWordNode } from '../../word/composite';
import { findLineBoundaryIndex, findOperatorEndIndex } from '../opaque/scan';
import { endAt, isWord, isWordStart, skipCommandTerm, takeKeyword } from './syntax';
import type { CompoundContents } from './types';

type LoopHeader = {
  readonly state: ParseState;
  readonly variables: readonly WordNode[];
  readonly words: readonly WordNode[] | null;
  readonly arithmetic: ArithmeticExpansionNode | null;
  readonly count: WordNode | null;
};

function headerAt(state: ParseState): LoopHeader {
  return { state, variables: [], words: null, arithmetic: null, count: null };
}

function readRepeatHeader(state: ParseState): LoopHeader {
  if (isWordStart(state)) {
    const count = readWordNode(state);

    return { ...headerAt(count.state), count: count.node };
  }

  return headerAt(
    addDiagnostic({
      state,
      kind: 'unexpectedToken',
      message: 'Expected repeat count',
      tokens: [currentToken(state)],
    }),
  );
}

function readArithmeticHeader(state: ParseState): LoopHeader {
  const start = state.index;
  const end = findOperatorEndIndex({
    tokens: state.tokens,
    index: state.index + 1,
    endOperatorKind: 'arithmeticEnd',
  });
  const diagnosed =
    end === null
      ? addDiagnostic({
          state,
          kind: 'missingArithmeticEnd',
          message: 'Missing arithmetic for closing delimiter',
          tokens: [currentToken(state)],
        })
      : state;
  const current = {
    ...diagnosed,
    index: end === null ? findLineBoundaryIndex(state.tokens, state.index + 1) : end + 1,
  };
  const tokens = tokenSlice(current, start, current.index);
  const arithmetic: ArithmeticExpansionNode = {
    kind: 'arithmeticExpansion',
    range: rangeFromTokens(tokens),
    raw: tokens.map((token) => token.value).join(''),
  };
  const invalid = end !== null && arithmeticSeparatorCount(arithmetic.raw.slice(2, -2)) !== 2;

  return {
    ...headerAt(
      invalid
        ? addDiagnostic({
            state: current,
            kind: 'unexpectedToken',
            message: 'Arithmetic for requires two clause separators',
            tokens,
          })
        : current,
    ),
    arithmetic,
  };
}

function readVariables(state: ParseState): {
  readonly state: ParseState;
  readonly variables: readonly WordNode[];
} {
  const initial = { current: state, names: collectArray<WordNode>() };

  return loop<
    typeof initial,
    {
      readonly state: ParseState;
      readonly variables: readonly WordNode[];
    }
  >(initial, (progress) => {
    const token = currentToken(progress.current);

    if (
      token.kind !== 'word' ||
      (!(progress.names.length === 0) && (isWord(token, 'in') || isWord(token, 'do')))
    ) {
      return done({ state: progress.current, variables: progress.names });
    }

    const word = readWordNode(progress.current);

    return again({
      current: skipInlineTrivia(word.state),
      names: appendItems(progress.names, word.node),
    });
  });
}

function readValues(state: ParseState): {
  readonly state: ParseState;
  readonly words: readonly WordNode[];
} {
  const initial = { current: state, words: collectArray<WordNode>() };

  return loop<
    typeof initial,
    {
      readonly state: ParseState;
      readonly words: readonly WordNode[];
    }
  >(initial, (progress) => {
    const token = currentToken(progress.current);

    if (
      token.kind === 'eof' ||
      token.kind === 'newline' ||
      token.operatorKind === 'semicolon' ||
      token.operatorKind === 'rightParen'
    ) {
      return done({ state: progress.current, words: progress.words });
    }

    const word = isWordStart(progress.current) ? readWordNode(progress.current) : null;

    return again({
      current: word ? skipInlineTrivia(word.state) : advanceState(progress.current),
      words: word ? appendItems(progress.words, word.node) : progress.words,
    });
  });
}

function readVariableHeader(state: ParseState, syntax: string): LoopHeader {
  const variables = readVariables(state);
  const current =
    variables.variables.length === 0
      ? addDiagnostic({
          state: variables.state,
          kind: 'unexpectedToken',
          message: 'Expected loop variable after ' + syntax,
          tokens: [currentToken(variables.state)],
        })
      : variables.state;
  const token = currentToken(current);
  const base = { ...headerAt(current), variables: variables.variables };

  if (!isWord(token, 'in') && token.operatorKind !== 'leftParen' && syntax !== 'foreach') {
    return base;
  }

  const values = readValues(skipTrivia(advanceState(current)));
  const next =
    token.operatorKind === 'leftParen' && currentToken(values.state).operatorKind === 'rightParen'
      ? advanceState(values.state)
      : values.state;

  return { ...base, state: next, words: values.words };
}

export function readIterationBody(
  state: ParseState,
  context: ParserContext,
  syntax: string,
  closeWord: string,
): NodeResult<CompoundContents> {
  const current = skipTrivia(state);
  const header =
    syntax === 'repeat'
      ? readRepeatHeader(current)
      : currentToken(current).operatorKind === 'arithmeticStart'
        ? readArithmeticHeader(current)
        : readVariableHeader(current, syntax);
  const terms = skipCommandTerm(header.state);
  const ready = syntax === 'foreach' ? terms : takeKeyword(terms, 'do').state;
  const body = context.parseNestedList(ready, endAt(closeWord));

  if (syntax !== 'for' && syntax !== 'select' && syntax !== 'foreach') {
    return {
      node: { kind: 'repeatCommand', count: header.count, body: body.node },
      state: body.state,
    };
  }

  const kind =
    syntax === 'for' ? 'forCommand' : syntax === 'select' ? 'selectCommand' : 'foreachCommand';

  return {
    node: {
      kind,
      variables: header.variables,
      words: header.words,
      arithmetic: header.arithmetic,
      body: body.node,
    },
    state: body.state,
  };
}

function arithmeticSeparatorCount(text: string): number {
  const initial = { index: 0, count: 0 };

  return loop<typeof initial, number>(initial, (state) => {
    const { index, count } = state;

    if (index >= text.length) {
      return done(count);
    }

    const char = text[index];

    if (char === '\\') {
      return again({ index: index + 2, count });
    }

    if (char === '$' && (text[index + 1] === '(' || text[index + 1] === '{')) {
      const kind =
        text[index + 1] === '{' ? 'brace' : text[index + 2] === '(' ? 'arithmetic' : 'paren';

      return again({ index: delimitedEnd(text, index + 1, kind) ?? text.length, count });
    }

    if (char === '(' || char === "'" || char === '"' || text.charCodeAt(index) === 96) {
      const kind =
        char === '('
          ? 'patternParen'
          : char === "'"
            ? 'single'
            : char === '"'
              ? 'double'
              : 'backtick';

      return again({ index: delimitedEnd(text, index, kind) ?? text.length, count });
    }

    return again({ index: index + 1, count: count + (char === ';' ? 1 : 0) });
  });
}
