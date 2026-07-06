import { current, position } from '../../cursor';
import type { Cursor } from '../../cursor';
import type { Token } from '../../token';
import { createToken } from '../../token';
import { isHorizontalWhitespace } from '../predicate';
import type { ReadResult } from './result';
import { readTextWhile } from './text';

type WhitespaceReadContext = {
  readonly sourceFile: string;
  readonly cursor: Cursor;
};

export function readWhitespace({
  sourceFile,
  cursor,
}: WhitespaceReadContext): ReadResult<Token> {
  const start = position(cursor);
  const result = readTextWhile({
    cursor,
    shouldContinue: (nextCursor) => isHorizontalWhitespace(current(nextCursor)),
  });

  return {
    value: createToken({
      kind: 'whitespace',
      value: result.value,
      sourceFile,
      start,
      end: position(result.cursor),
    }),
    cursor: result.cursor,
  };
}
