import type { ListTerminatorNode, ListTerminatorType } from '../../../ast';
import { advanceState, currentToken } from '../../state';
import type { NodeResult, ParseState } from '../../state';
import { listTerminatorType } from '../listTerminator';

export function readListTerminator(state: ParseState): NodeResult<ListTerminatorNode | null> {
  const token = currentToken(state);
  const type = listTerminatorType(token);

  if (!type) {
    return {
      node: null,
      state,
    };
  } else {
    return createListTerminatorNode(state, type);
  }
}

function createListTerminatorNode(
  state: ParseState,
  type: ListTerminatorType,
): NodeResult<ListTerminatorNode> {
  const token = currentToken(state);

  return {
    node: {
      kind: 'terminator',
      range: token.range,
      type,
    },
    state: advanceState(state),
  };
}
