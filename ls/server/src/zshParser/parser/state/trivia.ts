import { advanceState, currentToken } from './cursor';
import type { ParseState } from './types';

function skip(state: ParseState, comments: boolean, lines: boolean): ParseState {
  let current = state;
  while (true) {
    const token = currentToken(current);
    if (token.kind === 'whitespace' || token.kind === 'continuation' ||
      comments && (token.kind === 'comment' || token.kind === 'hereDocBody' || token.kind === 'hereDocEnd') ||
      lines && token.kind === 'newline') current = advanceState(current);
    else return current;
  }
}
export function skipTrivia(state: ParseState): ParseState { return skip(state, true, false); }
export function skipInlineTrivia(state: ParseState): ParseState { return skip(state, false, false); }
export function skipLineContinuingTrivia(state: ParseState): ParseState { return skip(state, true, true); }
