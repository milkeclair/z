import type { Token } from '../../lexer';
import type { ParseState } from './types';

export function currentToken(state: ParseState): Token {
  return state.tokens[state.index] ?? state.eof;
}

export function advanceState(state: ParseState, count = 1): ParseState {
  return {
    ...state,
    index: Math.min(state.index + count, state.tokens.length - 1),
  };
}

export function tokenSlice(
  state: ParseState,
  startIndex: number,
  endIndexExclusive: number,
): readonly Token[] {
  return state.tokens.slice(startIndex, endIndexExclusive);
}
