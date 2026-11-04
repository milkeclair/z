import { position } from '../../cursor';
import type { Cursor } from '../../cursor';
import type { Token } from '../../token';
import { createToken } from '../../token';
import { isNewline } from '../predicate';
import type { ReadResult } from './result';
import { readTextWhile } from './text';

type CommentReadContext = {
  readonly sourceFile: string;
  readonly cursor: Cursor;
};

export function readComment({ sourceFile, cursor }: CommentReadContext): ReadResult<Token> {
  const start = position(cursor);
  const result = readTextWhile({
    cursor,
    shouldContinue: (nextCursor) => !isNewline(nextCursor),
  });

  return {
    value: createToken({
      kind: 'comment',
      value: result.value,
      sourceFile,
      start,
      end: position(result.cursor),
    }),
    cursor: result.cursor,
  };
}
