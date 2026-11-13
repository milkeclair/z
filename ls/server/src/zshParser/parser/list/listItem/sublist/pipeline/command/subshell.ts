import type { SubshellCommandNode } from '../../../../../../ast';
import type { Token } from '../../../../../../lexer';
import { readPostCommandRedirects } from '../../../../../redirect';
import { rangeFromTokens, enclosingRange } from '../../../../../range';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipTrivia,
  tokenSlice,
} from '../../../../../state';
import type { NodeResult, ParseState } from '../../../../../state';
import type { ParserContext } from '../../../../../context';

export function parseSubshellCommand({
  state,
  context,
  readPostBodyRedirects,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly readPostBodyRedirects: boolean;
}): NodeResult<SubshellCommandNode> {
  const openParen = currentToken(state);
  const startIndex = state.index;
  const body = context.parseNestedList(advanceState(state), isSubshellEnd);
  const closeState = skipTrivia(body.state);
  const closeToken = currentToken(closeState);

  if (closeToken.operatorKind === 'rightParen') {
    const nextState = advanceState(closeState);
    const postBodyRedirects = readPostBodyRedirects ? readPostCommandRedirects(nextState) : {
      redirects: [],
      state: nextState,
    };
    const tokens = tokenSlice(postBodyRedirects.state, startIndex, postBodyRedirects.state.index);

    return {
      node: {
        kind: 'subshellCommand',
        range: enclosingRange(rangeFromTokens(tokens, openParen.range), postBodyRedirects.redirects),
        openParen: openParen.range,
        body: body.node,
        closeParen: closeToken.range,
        postBodyRedirects: postBodyRedirects.redirects,
      },
      state: postBodyRedirects.state,
    };
  } else {
    const diagnosed = addDiagnostic({
      state: closeState,
      kind: 'missingClosingParen',
      message: 'Missing closing parenthesis for subshell command',
      tokens: [openParen],
    });
    const tokens = tokenSlice(diagnosed, startIndex, diagnosed.index);

    return {
      node: {
        kind: 'subshellCommand',
        range: rangeFromTokens(tokens, openParen.range),
        openParen: openParen.range,
        body: body.node,
        closeParen: null,
        postBodyRedirects: [],
      },
      state: diagnosed,
    };
  }
}

function isSubshellEnd(token: Token): boolean {
  return token.kind === 'eof' || token.operatorKind === 'rightParen';
}
