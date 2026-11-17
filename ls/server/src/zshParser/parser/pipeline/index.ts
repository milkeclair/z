import { List } from 'immutable';
import { loop, again, done } from '../../../util/loop';
import type { PipelineNode } from '../../ast';
import { parseCommand } from '../command';
import type { ParserContext } from '../context';
import { enclosingRange, rangeFromTokens } from '../range';
import type { NodeResult, ParseState } from '../state';
import {
  advanceState,
  currentToken,
  skipLineContinuingTrivia,
  skipTrivia,
  tokenSlice,
} from '../state';
import { readPipelineModifier } from './modifier';
import { createPipelineOperatorNode, pipelineOperatorType } from './operator';
import { readPipelineTiming } from './timing';

type PipelineRestResult = {
  readonly rest: PipelineNode['rest'];
  readonly state: ParseState;
};

export function parsePipeline({
  state,
  context,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
}): NodeResult<PipelineNode> {
  const startState = skipTrivia(state);
  const startIndex = startState.index;
  const timing = readPipelineTiming(startState);
  const modifier = readPipelineModifier(timing.state);
  const command = parseCommand({
    state: modifier.state,
    context,
  });
  const rest = readPipelineRest({
    state: command.state,
    context,
    rest: [],
  });
  const tokens = tokenSlice(rest.state, startIndex, rest.state.index);

  return {
    node: {
      kind: 'pipeline',
      range: enclosingRange(rangeFromTokens(tokens, command.node.range), [
        command.node,
        ...rest.rest.map((item) => item.command),
      ]),
      timing: timing.timing,
      modifier: modifier.modifier,
      first: command.node,
      rest: rest.rest,
    },
    state: rest.state,
  };
}

function readPipelineRest({
  state,
  context,
  rest,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly rest: PipelineNode['rest'];
}): PipelineRestResult {
  const initial = {
    current: skipTrivia(state),
    collected: List<PipelineNode['rest'][number]>(rest),
  };
  return loop<typeof initial, PipelineRestResult>(initial, ({ current, collected }) => {
    const token = currentToken(current);
    const type = pipelineOperatorType(token);
    if (current.stopped || !type) {
      return done({ rest: collected.toArray(), state: current });
    }
    const parsed = parseCommand({
      state: skipLineContinuingTrivia(advanceState(current)),
      context,
    });
    return again({
      current: skipTrivia(parsed.state),
      collected: collected.push({
        operator: createPipelineOperatorNode(token, type),
        command: parsed.node,
      }),
    });
  });
}
