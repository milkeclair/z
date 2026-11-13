import { isProcessSubstitutionStart } from '../word/composite/token';
import type { RedirectNode, HereDocumentNode, WordNode } from '../../ast';
import type { SourceRange, Token } from '../../lexer';
import { areAdjacentTokens, rangeFromTokens } from '../range';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipInlineTrivia,
  tokenSlice,
} from '../state';
import type { NodeResult, ParseState } from '../state';
import { readWordNode } from '../word/composite';

type RedirectsReadResult = {
  readonly redirects: readonly RedirectNode[];
  readonly state: ParseState;
};

type RedirectReadResult = NodeResult<RedirectNode> & {
  readonly syntaxEndIndex: number;
};

export function isRedirectStart(state: ParseState): boolean {
  const token = currentToken(state);

  return !isProcessSubstitutionStart(state.tokens, state.index) && (token.operatorKind === 'redirect' || isFdRedirectStart(state));
}

export function readPostCommandRedirects(state: ParseState): RedirectsReadResult {
  const redirects: RedirectNode[] = [];
  let current = state;
  while (true) {
    const candidate = skipInlineTrivia(current);
    if (!isRedirectStart(candidate)) return { redirects, state: current };
    const result = readRedirectNode(candidate);
    redirects.push(result.node);
    current = result.state;
  }
}

export function readRedirectNode(state: ParseState): RedirectReadResult {
  const fd = readRedirectFd(state);
  const operator = fd ? currentToken(advanceState(state)) : currentToken(state);
  const operatorLength = fd ? 2 : 1;
  const afterOperator = skipInlineTrivia(advanceState(state, operatorLength));
  const targetToken = currentToken(afterOperator);
  const operatorValue = fd ? `${fd.value}${operator.value}` : operator.value;

  if (targetToken.kind === 'word' || isProcessSubstitutionStart(afterOperator.tokens, afterOperator.index)) {
    const target = operator.value === '<<' || operator.value === '<<-'
      ? readHereDocumentDelimiter(afterOperator) : readWordNode(afterOperator);
    const nextState = target.state;
    const bodyToken = (operator.value === '<<' || operator.value === '<<-') ? state.tokens.find((token) => token.kind === 'hereDocBody' && token.hereDoc?.operatorOffset === operator.range.start.offset) : undefined;
    const closingToken = bodyToken?.hereDoc?.closed ? state.tokens.find((token) => token.kind === 'hereDocEnd' && token.hereDoc?.operatorOffset === operator.range.start.offset) : undefined;
    const hereDocument: HereDocumentNode | null = bodyToken?.hereDoc ? {
      kind: 'hereDocument', range: bodyToken.range, raw: bodyToken.value, delimiter: bodyToken.hereDoc.delimiter,
      quoted: bodyToken.hereDoc.quoted, stripTabs: bodyToken.hereDoc.stripTabs, close: closingToken?.range ?? null,
    } : null;
    const tokens = tokenSlice(nextState, state.index, nextState.index);

    return {
      node: {
        kind: 'redirect',
        range: {
          start: (fd ?? operator).range.start,
          end: closingToken?.range.end ?? bodyToken?.range.end ?? target.node.range.end,
        },
        operator: operatorValue,
        target: target.node,
        hereDocument,
      },
      state: nextState,
      syntaxEndIndex: nextState.index,
    };
  } else {
    const diagnosed = addDiagnostic({
      state: afterOperator,
      kind: 'unexpectedToken',
      message: `Missing redirect target after ${operator.value}`,
      tokens: [operator],
    });

    return {
      node: {
        kind: 'redirect',
        range: redirectOperatorRange(fd, operator),
        operator: operatorValue,
        target: null,
        hereDocument: null,
      },
      state: diagnosed,
      syntaxEndIndex: state.index + operatorLength,
    };
  }
}

function readRedirectFd(state: ParseState): Token | null {
  return isFdRedirectStart(state) ? currentToken(state) : null;
}

function isFdRedirectStart(state: ParseState): boolean {
  const token = currentToken(state);
  const next = currentToken(advanceState(state));

  return token.kind === 'word' &&
    isDigits(token.value) &&
    next.operatorKind === 'redirect' &&
    areAdjacentTokens(token, next);
}

function redirectOperatorRange(fd: Token | null, operator: Token): SourceRange {
  if (!fd) {
    return operator.range;
  } else {
    return {
      start: fd.range.start,
      end: operator.range.end,
    };
  }
}

function isDigits(value: string): boolean {
  return value.length > 0 && [...value].every(isAsciiDigit);
}

function isAsciiDigit(char: string): boolean {
  return char >= '0' && char <= '9';
}

function readHereDocumentDelimiter(state: ParseState): NodeResult<WordNode> {
  const token = currentToken(state);
  return {
    node: {
      kind: 'word', range: token.range, raw: token.value, quoted: token.quoted, quoteKind: token.quoteKind,
      parts: [{ kind: 'stringLiteral', range: token.range, value: token.value }],
    },
    state: advanceState(state),
  };
}
