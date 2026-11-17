import { List } from 'immutable';
import { loop, again, done } from '../../../../util/loop';
import type { Token } from '../../../lexer';
import { areAdjacentTokens } from '../../range';
import { findNestedOperatorEnd, readExpansionAfterWord } from './expansion';

type TokenReadResult = { readonly tokens: readonly Token[]; readonly nextIndex: number };
type TokenSegment = TokenReadResult & { readonly finished?: true };

export function isProcessSubstitutionStart(tokens: readonly Token[], index: number): boolean {
  const token = tokens[index],
    next = tokens[index + 1];
  return Boolean(
    token &&
      ['<', '>', '='].includes(token.value) &&
      next?.operatorKind === 'leftParen' &&
      areAdjacentTokens(token, next),
  );
}
/** コマンド名の後では、対応する閉じ括弧を持つ先頭の括弧をglobの単語として扱える。 */
export function isParenthesizedWordStart(tokens: readonly Token[], index: number): boolean {
  return (
    tokens[index]?.operatorKind === 'leftParen' &&
    findNestedOperatorEnd({
      tokens,
      index,
      depth: 0,
      startOperatorKind: 'leftParen',
      endOperatorKind: 'rightParen',
    }) !== null
  );
}
function readWordSegment(tokens: readonly Token[], index: number): TokenSegment | null {
  const token = tokens[index];
  if (!token) {
    return null;
  }
  if (isProcessSubstitutionStart(tokens, index)) {
    const end =
      findNestedOperatorEnd({
        tokens,
        index: index + 1,
        depth: 0,
        startOperatorKind: 'leftParen',
        endOperatorKind: 'rightParen',
      }) ?? Math.max(index + 1, tokens.length - 2);
    return { tokens: tokens.slice(index, end + 1), nextIndex: end + 1 };
  }
  if (token.operatorKind === 'leftParen') {
    const end = findNestedOperatorEnd({
      tokens,
      index,
      depth: 0,
      startOperatorKind: 'leftParen',
      endOperatorKind: 'rightParen',
    });
    return end === null ? null : { tokens: tokens.slice(index, end + 1), nextIndex: end + 1 };
  }
  if (token.kind !== 'word') {
    return null;
  }
  const expansion = readExpansionAfterWord(tokens, index),
    next = tokens[index + 1];
  if (expansion) {
    return { tokens: [token, ...expansion.tokens], nextIndex: expansion.endIndex + 1 };
  }
  if (
    next &&
    areAdjacentTokens(token, next) &&
    (next.operatorKind === 'leftParen' || next.operatorKind === 'leftBrace')
  ) {
    const brace = next.operatorKind === 'leftBrace';
    const end = findNestedOperatorEnd({
      tokens,
      index: index + 1,
      depth: 0,
      lexicalKind: brace ? 'brace' : token.value.endsWith('=') ? 'arrayParen' : 'patternParen',
      startOperatorKind: brace ? 'leftBrace' : 'leftParen',
      endOperatorKind: brace ? 'rightBrace' : 'rightParen',
    });
    return end === null
      ? { tokens: [token], nextIndex: index + 1, finished: true }
      : { tokens: tokens.slice(index, end + 1), nextIndex: end + 1 };
  }
  return next?.operatorKind === 'conditionEnd' && areAdjacentTokens(token, next)
    ? { tokens: [token, next], nextIndex: index + 2 }
    : { tokens: [token], nextIndex: index + 1 };
}
export function readWordTokens({
  tokens,
  index,
  collected,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly collected: readonly Token[];
}): TokenReadResult {
  const initial = { index, parts: List(collected) };
  return loop<typeof initial, TokenReadResult>(initial, (progress) => {
    const segment = readWordSegment(tokens, progress.index);
    if (!segment) {
      return done({ tokens: progress.parts.toArray(), nextIndex: progress.index });
    }
    const parts = progress.parts.concat(segment.tokens);
    const previous = parts.last(),
      next = tokens[segment.nextIndex];
    const adjacent = previous && next && areAdjacentTokens(previous, next);
    const continued =
      next?.kind === 'word' || isProcessSubstitutionStart(tokens, segment.nextIndex);
    return !segment.finished && adjacent && continued
      ? again({ index: segment.nextIndex, parts })
      : done({ tokens: parts.toArray(), nextIndex: segment.nextIndex });
  });
}
