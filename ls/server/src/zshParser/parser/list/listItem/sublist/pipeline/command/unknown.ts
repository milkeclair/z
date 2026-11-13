import type { UnknownNode } from '../../../../../../ast';
import type { Token } from '../../../../../../lexer';
import { addDiagnostic, advanceState } from '../../../../../state';
import type { NodeResult, ParseState } from '../../../../../state';

export function createUnknownCommand(
  state: ParseState,
  token: Token,
  message: string,
  options: { readonly consume?: boolean } = {},
): NodeResult<UnknownNode> {
  const diagnosed = addDiagnostic({
    state,
    kind: 'unknownCommand',
    message,
    tokens: [token],
  });
  const consume = options.consume ?? true;
  const nextState = token.kind === 'eof' || !consume ? diagnosed : advanceState(diagnosed);

  return {
    node: {
      kind: 'unknown',
      range: token.range,
      reason: 'unknownCommand',
    },
    state: nextState,
  };
}
