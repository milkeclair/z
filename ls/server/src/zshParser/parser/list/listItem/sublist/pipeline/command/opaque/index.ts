import type { OpaqueCommandNode } from '../../../../../../../ast';
import { readPostCommandRedirects } from '../../../../../../redirect';
import { rangeFromTokens, enclosingRange, textForRange } from '../../../../../../range';
import { addDiagnostic, advanceState, currentToken, tokenSlice } from '../../../../../../state';
import type { NodeResult, ParseState } from '../../../../../../state';
import { findLineBoundaryIndex, findOperatorEndIndex } from './scan';

export function parseOpaqueCommandIfStart({
  state, readPostBodyRedirects,
}: { readonly state: ParseState; readonly readPostBodyRedirects: boolean }): NodeResult<OpaqueCommandNode> | null {
  const open = currentToken(state);
  if (open.operatorKind !== 'conditionStart' && open.operatorKind !== 'arithmeticStart') return null;
  const condition = open.operatorKind === 'conditionStart';
  const endIndex = findOperatorEndIndex({ tokens: state.tokens, index: state.index + 1, endOperatorKind: condition ? 'conditionEnd' : 'arithmeticEnd' });
  const next = endIndex === null ? {
    ...addDiagnostic({ state, kind: condition ? 'missingConditionEnd' : 'missingArithmeticEnd',
      message: condition ? 'Missing closing ]] for condition command' : 'Missing closing )) for arithmetic command', tokens: [open] }),
    index: findLineBoundaryIndex(state.tokens, state.index + 1),
  } : advanceState(state, endIndex - state.index + 1);
  const post = endIndex !== null && readPostBodyRedirects ? readPostCommandRedirects(next) : { state: next, redirects: [] };
  const tokens = tokenSlice(post.state, state.index, post.state.index);
  const headerRange = rangeFromTokens(tokens, open.range);
  const range = enclosingRange(headerRange, post.redirects);
  return { node: {
    kind: 'opaqueCommand', syntax: condition ? 'condition' : 'arithmetic', range,
    raw: range.end.offset === headerRange.end.offset ? tokens.map((token) => token.value).join('') : textForRange(state.tokens, range), open: open.range, close: endIndex === null ? null : state.tokens[endIndex].range,
    postBodyRedirects: post.redirects,
  }, state: post.state };
}
