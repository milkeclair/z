import { findLineBoundaryIndex } from '../opaque/scan';
import { parseCommand } from '..';
import type { CommandNode, CompoundCommandNode, ListNode } from '../../../ast';
import type { Token } from '../../../lexer';
import type { ParserContext } from '../../context';
import { enclosingRange, rangeFromTokens, textForRange } from '../../range';
import { readPostCommandRedirects } from '../../redirect';
import type { NodeResult, ParseState } from '../../state';
import { advanceState, currentToken, skipTrivia, tokenSlice } from '../../state';
import { readWordNode } from '../../word/composite';
import { readCaseBody } from './case';
import { readConditionalLoopBody, readIfBody } from './conditional';
import { readIterationBody } from './iteration';
import { isWord, isWordStart, skipTerms, takeKeyword } from './syntax';
import type { CompoundContents } from './types';

const reserved = ['if', 'while', 'until', 'for', 'select', 'foreach', 'repeat', 'case'];

export function isCompoundStart(token: Token): boolean {
  return token.kind === 'word' && !token.quoted && reserved.includes(token.value);
}

export function parseCompoundCommand({
  state,
  context,
  readPostBodyRedirects,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly readPostBodyRedirects: boolean;
}): NodeResult<CompoundCommandNode> {
  const syntax = currentToken(state).value;
  const closeWord =
    syntax === 'if' ? 'fi' : syntax === 'case' ? 'esac' : syntax === 'foreach' ? 'end' : 'done';
  if (syntax === 'repeat' && isWordStart(skipTrivia(advanceState(state)))) {
    const count = readWordNode(skipTrivia(advanceState(state)));
    if (!isWord(currentToken(skipTerms(count.state)), 'do')) {
      return parseShortRepeat(state, context, readPostBodyRedirects);
    }
  }
  const result = parseCompoundWithin(state, context, readPostBodyRedirects, closeWord);
  if (result.node.close !== null || result.state.stopped) {
    return result;
  }
  const boundary = findLineBoundaryIndex(state.tokens, state.index);
  if (state.tokens[boundary]?.kind === 'eof') {
    return result;
  }
  const at = state.tokens[boundary] ?? state.eof;
  const eof: Token = { ...state.eof, range: { start: at.range.start, end: at.range.start } };
  const window = { ...state, tokens: [...state.tokens.slice(0, boundary), eof], eof };
  const recovered = parseCompoundWithin(window, context, readPostBodyRedirects, closeWord);
  return {
    node: recovered.node,
    state: { ...recovered.state, tokens: state.tokens, eof: state.eof, index: boundary },
  };
}

function listFromCommand(command: CommandNode): ListNode {
  const range = command.range;
  return {
    kind: 'list',
    range,
    items: [
      {
        kind: 'listItem',
        range,
        terminator: null,
        sublist: {
          kind: 'sublist',
          range,
          rest: [],
          first: {
            kind: 'pipeline',
            range,
            timing: null,
            modifier: null,
            first: command,
            rest: [],
          },
        },
      },
    ],
  };
}

function parseShortRepeat(
  state: ParseState,
  context: ParserContext,
  redirects: boolean,
): NodeResult<CompoundCommandNode> {
  const keyword = currentToken(state);
  const count = readWordNode(skipTrivia(advanceState(state)));
  const result = parseCommand({
    state: skipTrivia(count.state),
    context,
    readPostBodyRedirects: false,
  });
  const post = redirects
    ? readPostCommandRedirects(result.state)
    : { state: result.state, redirects: [] };
  const tokens = tokenSlice(post.state, state.index, post.state.index);
  const headerRange = rangeFromTokens(tokens, keyword.range);
  const range = enclosingRange(headerRange, [result.node, ...post.redirects]);
  return {
    node: {
      kind: 'repeatCommand',
      range,
      raw:
        range.end.offset === headerRange.end.offset
          ? tokens.map((token) => token.value).join('')
          : textForRange(state.tokens, range),
      keyword: keyword.range,
      close: null,
      postBodyRedirects: post.redirects,
      count: count.node,
      body: listFromCommand(result.node),
    },
    state: post.state,
  };
}
function readCompoundContents(
  state: ParseState,
  context: ParserContext,
  open: Token,
  closeWord: string,
): NodeResult<CompoundContents> {
  switch (open.value) {
    case 'if':
      return readIfBody(state, context, open);
    case 'while':
      return readConditionalLoopBody(state, context, 'whileCommand');
    case 'until':
      return readConditionalLoopBody(state, context, 'untilCommand');
    case 'case':
      return readCaseBody(state, context);
    default:
      return readIterationBody(state, context, open.value, closeWord);
  }
}
function parseCompoundWithin(
  state: ParseState,
  context: ParserContext,
  redirects: boolean,
  closeWord: string,
): NodeResult<CompoundCommandNode> {
  const open = currentToken(state);
  const contents = readCompoundContents(advanceState(state), context, open, closeWord);
  const close = takeKeyword(contents.state, closeWord);
  const post = redirects
    ? readPostCommandRedirects(close.state)
    : { state: close.state, redirects: [] };
  const tokens = tokenSlice(post.state, state.index, post.state.index);
  const headerRange = rangeFromTokens(tokens, open.range);
  const range = enclosingRange(headerRange, post.redirects);
  const base = {
    range,
    raw:
      range.end.offset === headerRange.end.offset
        ? tokens.map((token) => token.value).join('')
        : textForRange(state.tokens, range),
    keyword: open.range,
    close: close.token?.range ?? null,
    postBodyRedirects: post.redirects,
  };
  return { node: { ...base, ...contents.node }, state: post.state };
}
