import type { SublistContinuation, SublistNode } from '../../../../ast';
import { rangeFromTokens, enclosingRange } from '../../../range';
import {
  advanceState,
  currentToken,
  skipLineContinuingTrivia,
  skipTrivia,
  tokenSlice,
} from '../../../state';
import type { NodeResult, ParseState } from '../../../state';
import type { ParserContext } from '../../../context';
import { createLogicalOperatorNode, logicalOperatorType } from './operator';
import { parsePipeline } from './pipeline';

type SublistRestResult = {
  readonly rest: readonly SublistContinuation[];
  readonly state: ParseState;
};

export function parseSublist({
  state,
  context,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
}): NodeResult<SublistNode> {
  const startState = skipTrivia(state);
  const startIndex = startState.index;
  const first = parsePipeline({
    state: startState,
    context,
  });
  const rest = readSublistRest({
    state: first.state,
    context,
    rest: [],
  });
  const tokens = tokenSlice(rest.state, startIndex, rest.state.index);

  return {
    node: {
      kind: 'sublist',
      range: enclosingRange(rangeFromTokens(tokens, first.node.range), [first.node, ...rest.rest.map((item) => item.pipeline)]),
      first: first.node,
      rest: rest.rest,
    },
    state: rest.state,
  };
}

function readSublistRest({
  state,
  context,
  rest,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly rest: readonly SublistContinuation[];
}): SublistRestResult {
  const collected = [...rest];
  let current = skipTrivia(state);
  while (true) {
    const token = currentToken(current); const type = logicalOperatorType(token);
    if (current.stopped || !type) return { rest: collected, state: current };
    const pipeline = parsePipeline({ state: skipLineContinuingTrivia(advanceState(current)), context });
    collected.push({ operator: createLogicalOperatorNode(token, type), pipeline: pipeline.node });
    current = skipTrivia(pipeline.state);
  }
}
