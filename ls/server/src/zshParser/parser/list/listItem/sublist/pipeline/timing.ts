import type { PipelineTimingNode } from '../../../../../ast';
import {
  advanceState,
  currentToken,
  skipTrivia,
} from '../../../../state';
import type { ParseState } from '../../../../state';

const Time = 'time';

type PipelineTimingResult = {
  readonly timing: PipelineTimingNode | null;
  readonly state: ParseState;
};

export function readPipelineTiming(state: ParseState): PipelineTimingResult {
  const current = skipTrivia(state);
  const token = currentToken(current);

  if (token.kind === 'word' && !token.quoted && token.value === Time) {
    return {
      timing: {
        kind: 'pipelineTiming',
        range: token.range,
      },
      state: advanceState(current),
    };
  } else {
    return {
      timing: null,
      state: current,
    };
  }
}
