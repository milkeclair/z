import { parseCommand } from './index';
import type { AlwaysClauseNode, GroupCommandNode } from '../../../../../../ast';
import type { Token } from '../../../../../../lexer';
import { readPostCommandRedirects } from '../../../../../redirect';
import { rangeFromTokens, enclosingRange } from '../../../../../range';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipInlineTrivia,
  skipTrivia,
  tokenSlice,
} from '../../../../../state';
import type { NodeResult, ParseState } from '../../../../../state';
import type { ParserContext } from '../../../../../context';
import { skipCommandTerm } from './term';

export function parseGroupCommand({
  state,
  context,
  readPostBodyRedirects,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly readPostBodyRedirects: boolean;
}): NodeResult<GroupCommandNode> {
  const openBrace = currentToken(state);
  const startIndex = state.index;
  const body = context.parseNestedList(advanceState(state), isGroupEnd);
  const closeState = skipTrivia(body.state);
  const closeToken = currentToken(closeState);

  if (closeToken.operatorKind === 'rightBrace') {
    const nextState = advanceState(closeState);
    const always = readAlwaysClause({
      state: nextState,
      context,
      readPostBodyRedirects,
    });
    const postBodyRedirects = readPostBodyRedirects ? readPostCommandRedirects(always.state) : {
      redirects: [],
      state: always.state,
    };
    const tokens = tokenSlice(postBodyRedirects.state, startIndex, postBodyRedirects.state.index);

    return {
      node: {
        kind: 'groupCommand',
        range: enclosingRange(rangeFromTokens(tokens, openBrace.range), [...postBodyRedirects.redirects, ...(always.node ? [always.node] : [])]),
        openBrace: openBrace.range,
        body: body.node,
        closeBrace: closeToken.range,
        always: always.node,
        postBodyRedirects: postBodyRedirects.redirects,
      },
      state: postBodyRedirects.state,
    };
  } else {
    const diagnosed = addDiagnostic({
      state: closeState,
      kind: 'missingClosingBrace',
      message: 'Missing closing brace for group command',
      tokens: [openBrace],
    });
    const tokens = tokenSlice(diagnosed, startIndex, diagnosed.index);

    return {
      node: {
        kind: 'groupCommand',
        range: rangeFromTokens(tokens, openBrace.range),
        openBrace: openBrace.range,
        body: body.node,
        closeBrace: null,
        always: null,
        postBodyRedirects: [],
      },
      state: diagnosed,
    };
  }
}

function isGroupEnd(token: Token): boolean {
  return token.kind === 'eof' || token.operatorKind === 'rightBrace';
}

function readAlwaysClause({
  state,
  context,
  readPostBodyRedirects,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly readPostBodyRedirects: boolean;
}): NodeResult<AlwaysClauseNode | null> {
  const current = skipInlineTrivia(state);
  const token = currentToken(current);

  if (token.kind !== 'word' || token.quoted || token.value !== 'always') {
    return {
      node: null,
      state,
    };
  } else {
    const bodyState = skipCommandTerm(advanceState(current));
    const bodyStart = currentToken(bodyState);

    if (bodyStart.operatorKind !== 'leftBrace') {
      return {
        node: null,
        state,
      };
    } else {
      const body = parseCommand({
        state: bodyState,
        context,
        readPostBodyRedirects,
      });

      if (body.node.kind !== 'groupCommand' && body.node.kind !== 'unknown') throw new Error('Expected group or partial unknown for always body');
      return {
        node: {
          kind: 'alwaysClause',
          range: {
            start: token.range.start,
            end: body.node.range.end,
          },
          keyword: token.range,
          body: body.node,
        },
        state: body.state,
      };
    }
  }
}
