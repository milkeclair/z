import { advanceState, currentToken, skipTrivia } from '../../../../../state';
import type { ParseState } from '../../../../../state';

export function skipCommandTerm(state: ParseState): ParseState {
  let current = skipTrivia(state);
  while (currentToken(current).kind === 'newline' || currentToken(current).operatorKind === 'semicolon') current = skipTrivia(advanceState(current));
  return current;
}
