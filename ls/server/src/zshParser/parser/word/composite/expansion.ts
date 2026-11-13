import type { DelimiterKind } from '../../../lexer/delimiter';
import type { Token } from '../../../lexer';
import { delimitedEnd } from '../../../lexer/delimiter';
import { areAdjacentTokens } from '../../range';
import type { ExpansionNodeKind } from '../expansionNode';

export type ExpansionAfterWord = {
  readonly kind: ExpansionNodeKind; readonly tokens: readonly Token[]; readonly endIndex: number;
};
export function readExpansionAfterWord(tokens: readonly Token[], index: number): ExpansionAfterWord | null {
  const token = tokens[index]; const next = tokens[index + 1];
  if (!token || !next || !token.value.endsWith('$') || !areAdjacentTokens(token, next)) return null;
  const kind = next.operatorKind === 'leftBrace' ? 'parameterExpansion'
    : next.operatorKind === 'leftParen' ? 'commandSubstitution'
      : next.operatorKind === 'arithmeticStart' ? 'arithmeticExpansion' : null;
  if (!kind) return null;
  const endIndex = findDelimitedTokenEnd(tokens, index + 1, kind === 'parameterExpansion' ? 'brace' : kind === 'arithmeticExpansion' ? 'arithmetic' : 'paren');
  return endIndex === null ? null : { kind, tokens: tokens.slice(index + 1, endIndex + 1), endIndex };
}
export function findNestedOperatorEnd({
  tokens, index, startOperatorKind, lexicalKind,
}: {
  readonly tokens: readonly Token[]; readonly index: number; readonly depth: number;
  readonly lexicalKind?: DelimiterKind;
  readonly startOperatorKind: NonNullable<Token['operatorKind']>;
  readonly endOperatorKind: NonNullable<Token['operatorKind']>;
}): number | null {
  return findDelimitedTokenEnd(tokens, index, lexicalKind ?? (startOperatorKind === 'leftBrace' ? 'brace' : startOperatorKind === 'arithmeticStart' ? 'arithmetic' : 'paren'));
}
function findDelimitedTokenEnd(tokens: readonly Token[], index: number, kind: DelimiterKind): number | null {
  const text = tokens.slice(index).map((token) => token.value).join('');
  const end = delimitedEnd(text, 0, kind);
  if (end === null) return null;
  let length = 0;
  for (let cursor = index; cursor < tokens.length; cursor += 1) {
    length += tokens[cursor].value.length;
    if (length >= end) return cursor;
  }
  return null;
}
