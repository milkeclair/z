import type { ListNode } from '../../../ast';
import type { Token } from '../../../lexer';
import type { ParseState } from '../../state';
import { addDiagnostic, advanceState, currentToken, skipTrivia } from '../../state';
import { isProcessSubstitutionStart } from '../../word/composite/token';

export function isWordStart(state: ParseState): boolean {
  return (
    currentToken(state).kind === 'word' || isProcessSubstitutionStart(state.tokens, state.index)
  );
}

export function isWord(token: Token, value: string): boolean {
  return token.kind === 'word' && !token.quoted && token.value === value;
}

export function endAt(...words: readonly string[]) {
  return (token: Token): boolean =>
    token.kind === 'eof' || words.some((word) => isWord(token, word));
}

export function skipTerms(state: ParseState): ParseState {
  let current = skipTrivia(state);
  while (
    currentToken(current).kind === 'newline' ||
    currentToken(current).operatorKind === 'semicolon'
  ) {
    current = skipTrivia(advanceState(current));
  }
  return current;
}

export function takeKeyword(
  state: ParseState,
  value: string,
): { readonly token: Token | null; readonly state: ParseState } {
  const current = skipTrivia(state);
  const token = currentToken(current);
  if (isWord(token, value)) {
    return { token, state: advanceState(current) };
  }
  return {
    token: null,
    state: addDiagnostic({
      state: current,
      kind: 'missingCompoundEnd',
      message: 'Expected ' + value,
      tokens: [token],
    }),
  };
}

export function emptyList(state: ParseState): ListNode {
  const position = currentToken(state).range.start;
  return { kind: 'list', range: { start: position, end: position }, items: [] };
}
