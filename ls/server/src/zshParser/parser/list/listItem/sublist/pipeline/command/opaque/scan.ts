import { delimitedEnd } from '../../../../../../../lexer/delimiter';
import type { OperatorKind, Token } from '../../../../../../../lexer';

export function findOperatorEndIndex({
  tokens,
  index,
  endOperatorKind,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly endOperatorKind: OperatorKind;
}): number | null {
  const start = index - 1;
  const text = tokens.slice(start).map((token) => token.value).join('');
  const end = delimitedEnd(text, 0, endOperatorKind === 'conditionEnd' ? 'condition' : 'arithmetic');
  if (end === null) return null;
  let length = 0;
  for (let cursor = start; cursor < tokens.length; cursor += 1) {
    length += tokens[cursor].value.length;
    if (length >= end) return cursor;
  }
  return null;
}

export function findLineBoundaryIndex(tokens: readonly Token[], index: number): number {
  let cursor = index;
  while (tokens[cursor] && tokens[cursor].kind !== 'eof' && tokens[cursor].kind !== 'newline') cursor += 1;
  return cursor;
}
