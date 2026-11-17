import { again, done, loop } from '../../../../util/loop';
import type { OperatorKind, Token } from '../../../lexer';
import { delimitedEnd } from '../../../lexer/delimiter';

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
  const text = tokens
    .slice(start)
    .map((token) => token.value)
    .join('');
  const end = delimitedEnd(
    text,
    0,
    endOperatorKind === 'conditionEnd' ? 'condition' : 'arithmetic',
  );
  if (end === null) {
    return null;
  }
  const initial = { index: start, length: 0 };
  return loop<typeof initial, number | null>(initial, (state) => {
    const token = tokens[state.index];
    if (!token) {
      return done(null);
    }
    const length = state.length + token.value.length;
    return length >= end ? done(state.index) : again({ index: state.index + 1, length });
  });
}

export function findLineBoundaryIndex(tokens: readonly Token[], index: number): number {
  return loop(index, (cursor) => {
    const token = tokens[cursor];
    return token && token.kind !== 'eof' && token.kind !== 'newline'
      ? again(cursor + 1)
      : done(cursor);
  });
}
