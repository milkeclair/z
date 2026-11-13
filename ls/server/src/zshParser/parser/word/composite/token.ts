import type { Token } from '../../../lexer';
import { areAdjacentTokens } from '../../range';
import { findNestedOperatorEnd, readExpansionAfterWord } from './expansion';

type TokenReadResult = { readonly tokens: readonly Token[]; readonly nextIndex: number };

export function isProcessSubstitutionStart(tokens: readonly Token[], index: number): boolean {
  const token = tokens[index]; const next = tokens[index + 1];
  return Boolean(token && ['<', '>', '='].includes(token.value) && next?.operatorKind === 'leftParen' && areAdjacentTokens(token, next));
}
export function readWordTokens({
  tokens, index, collected,
}: { readonly tokens: readonly Token[]; readonly index: number; readonly collected: readonly Token[] }): TokenReadResult {
  const parts: Token[] = [...collected];
  let cursor = index;
  while (cursor < tokens.length) {
    const token = tokens[cursor];
    if (isProcessSubstitutionStart(tokens, cursor)) {
      const end = findNestedOperatorEnd({ tokens, index: cursor + 1, depth: 0, startOperatorKind: 'leftParen', endOperatorKind: 'rightParen' })
        ?? Math.max(cursor + 1, tokens.length - 2);
      parts.push(...tokens.slice(cursor, end + 1)); cursor = end + 1;
    } else if (token.kind === 'word') {
      parts.push(token);
      const expansion = readExpansionAfterWord(tokens, cursor);
      const next = tokens[cursor + 1];
      if (expansion) { parts.push(...expansion.tokens); cursor = expansion.endIndex + 1; }
      else if (next && areAdjacentTokens(token, next) && (next.operatorKind === 'leftParen' || next.operatorKind === 'leftBrace')) {
        const brace = next.operatorKind === 'leftBrace';
        const end = findNestedOperatorEnd({ tokens, index: cursor + 1, depth: 0,
          lexicalKind: brace ? 'brace' : token.value.endsWith('=') ? 'arrayParen' : 'patternParen',
          startOperatorKind: brace ? 'leftBrace' : 'leftParen', endOperatorKind: brace ? 'rightBrace' : 'rightParen' });
        if (end === null) { cursor += 1; break; }
        parts.push(...tokens.slice(cursor + 1, end + 1)); cursor = end + 1;
      } else if (next?.operatorKind === 'conditionEnd' && areAdjacentTokens(token, next)) {
        parts.push(next); cursor += 2;
      } else cursor += 1;
    } else break;
    const previous = parts[parts.length - 1]; const next = tokens[cursor];
    if (!next || !areAdjacentTokens(previous, next) || next.kind !== 'word' && !isProcessSubstitutionStart(tokens, cursor)) break;
  }
  return { tokens: parts, nextIndex: cursor };
}
