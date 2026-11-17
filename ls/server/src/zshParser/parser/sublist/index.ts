import { appendItems, collectArray } from '../../../util/collections';
import { again, done, loop } from '../../../util/loop';
import type { SublistContinuation, SublistNode } from '../../ast';
import type { ParserContext } from '../context';
import { parsePipeline } from '../pipeline';
import { enclosingRange, rangeFromTokens } from '../range';
import type { NodeResult, ParseState } from '../state';
import {
  advanceState,
  currentToken,
  skipLineContinuingTrivia,
  skipTrivia,
  tokenSlice,
} from '../state';
import { createLogicalOperatorNode, logicalOperatorType } from './operator';

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
      range: enclosingRange(rangeFromTokens(tokens, first.node.range), [
        first.node,
        ...rest.rest.map((item) => item.pipeline),
      ]),
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
  const initial = {
    current: skipTrivia(state),
    collected: collectArray<SublistContinuation>(rest),
  };

  return loop<typeof initial, SublistRestResult>(initial, ({ current, collected }) => {
    const token = currentToken(current);
    const type = logicalOperatorType(token);

    if (current.stopped || !type) {
      return done({ rest: collected, state: current });
    }

    const parsed = parsePipeline({
      state: skipLineContinuingTrivia(advanceState(current)),
      context,
    });

    return again({
      current: skipTrivia(parsed.state),
      collected: appendItems(collected, {
        operator: createLogicalOperatorNode(token, type),
        pipeline: parsed.node,
      }),
    });
  });
}
