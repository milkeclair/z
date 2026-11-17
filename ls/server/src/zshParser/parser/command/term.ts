import { again, done, loop } from '../../../util/loop';
import type { ParseState } from '../state';
import { advanceState, currentToken, skipTrivia } from '../state';
export function skipCommandTerm(state: ParseState): ParseState {
  return loop(skipTrivia(state), (current) => {
    const token = currentToken(current);
    return token.kind === 'newline' || token.operatorKind === 'semicolon'
      ? again(skipTrivia(advanceState(current)))
      : done(current);
  });
}
