import { advance, eof } from '../../../cursor';
import type { Cursor } from '../../../cursor';
import type { ReadResult } from '../result';

export function readBackslash(cursor: Cursor): ReadResult<string> {
  const result = advance(cursor);

  if (eof(result.cursor)) {
    return result;
  } else {
    const escaped = advance(result.cursor);

    return {
      value: result.value + escaped.value,
      cursor: escaped.cursor,
    };
  }
}
