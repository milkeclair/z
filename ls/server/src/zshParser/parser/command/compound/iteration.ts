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
import { emptyList, endAt, isWord, isWordStart, skipTerms, takeKeyword } from './syntax';
import type { CompoundContents } from './types';
export function readIterationBody(
  state: ParseState,
  context: ParserContext,
  syntax: string,
  closeWord: string,
): NodeResult<CompoundContents> {
  let current = state;
  let variables: readonly WordNode[] = [];
  let words: readonly WordNode[] | null = null;
  let arithmetic: ArithmeticExpansionNode | null = null;
  let count: WordNode | null = null;
  let body = emptyList(current);

  current = skipTrivia(current);

  if (syntax === 'repeat') {
    if (isWordStart(current)) {
      const word = readWordNode(current);
      count = word.node;
      current = word.state;
    } else {
      current = addDiagnostic({
        state: current,
        kind: 'unexpectedToken',
        message: 'Expected repeat count',
        tokens: [currentToken(current)],
      });
    }
  } else if (currentToken(current).operatorKind === 'arithmeticStart') {
    const start = current.index;
    const end = findOperatorEndIndex({
      tokens: current.tokens,
      index: current.index + 1,
      endOperatorKind: 'arithmeticEnd',
    });
    if (end === null) {
      current = addDiagnostic({
        state: current,
        kind: 'missingArithmeticEnd',
        message: 'Missing arithmetic for closing delimiter',
        tokens: [currentToken(current)],
      });
    }
    current = {
      ...current,
      index: end === null ? findLineBoundaryIndex(current.tokens, current.index + 1) : end + 1,
    };
    const tokens = tokenSlice(current, start, current.index);
    arithmetic = {
      kind: 'arithmeticExpansion',
      range: rangeFromTokens(tokens),
      raw: tokens.map((token) => token.value).join(''),
    };
    if (end !== null && arithmeticSeparatorCount(arithmetic.raw.slice(2, -2)) !== 2) {
      current = addDiagnostic({
        state: current,
        kind: 'unexpectedToken',
        message: 'Arithmetic for requires two clause separators',
        tokens,
      });
    }
  } else {
    const names: WordNode[] = [];
    while (
      currentToken(current).kind === 'word' &&
      (names.length === 0 ||
        (!isWord(currentToken(current), 'in') && !isWord(currentToken(current), 'do')))
    ) {
      const word = readWordNode(current);
      names.push(word.node);
      current = skipInlineTrivia(word.state);
    }
    variables = names;
    if (names.length === 0) {
      current = addDiagnostic({
        state: current,
        kind: 'unexpectedToken',
        message: 'Expected loop variable after ' + syntax,
        tokens: [currentToken(current)],
      });
    }
    if (
      isWord(currentToken(current), 'in') ||
      currentToken(current).operatorKind === 'leftParen' ||
      syntax === 'foreach'
    ) {
      const parenthesized = currentToken(current).operatorKind === 'leftParen';
      current = skipTrivia(advanceState(current));
      const values: WordNode[] = [];
      while (
        currentToken(current).kind !== 'eof' &&
        currentToken(current).kind !== 'newline' &&
        currentToken(current).operatorKind !== 'semicolon' &&
        currentToken(current).operatorKind !== 'rightParen'
      ) {
        if (isWordStart(current)) {
          const word = readWordNode(current);
          values.push(word.node);
          current = skipInlineTrivia(word.state);
        } else {
          current = advanceState(current);
        }
      }
      words = values;
      if (parenthesized && currentToken(current).operatorKind === 'rightParen') {
        current = advanceState(current);
      }
    }
  }

  current = skipTerms(current);

  if (syntax !== 'foreach') {
    current = takeKeyword(current, 'do').state;
  }

  const result = context.parseNestedList(current, endAt(closeWord));

  body = result.node;

  current = result.state;
  if (syntax !== 'for' && syntax !== 'select' && syntax !== 'foreach')
    return { node: { kind: 'repeatCommand', count, body }, state: current };
  const kind =
    syntax === 'for' ? 'forCommand' : syntax === 'select' ? 'selectCommand' : 'foreachCommand';
  return { node: { kind, variables, words, arithmetic, body }, state: current };
}
function arithmeticSeparatorCount(text: string): number {
  let count = 0;
  let index = 0;
  while (index < text.length) {
    const char = text[index];
    if (char === '\\') {
      index += 2;
      continue;
    }
    if (char === '$' && (text[index + 1] === '(' || text[index + 1] === '{')) {
      const kind =
        text[index + 1] === '{' ? 'brace' : text[index + 2] === '(' ? 'arithmetic' : 'paren';
      index = delimitedEnd(text, index + 1, kind) ?? text.length;
    } else if (char === '(' || char === "'" || char === '"' || text.charCodeAt(index) === 96) {
      const kind =
        char === '('
          ? 'patternParen'
          : char === "'"
            ? 'single'
            : char === '"'
              ? 'double'
              : 'backtick';
      index = delimitedEnd(text, index, kind) ?? text.length;
    } else {
      if (char === ';') {
        count += 1;
      }
      index += 1;
    }
  }
  return count;
}
