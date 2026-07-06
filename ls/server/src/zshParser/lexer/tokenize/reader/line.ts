import { SpecialCharacters } from '../../character';
import { advance, current, startsWith } from '../../cursor';
import type { Cursor } from '../../cursor';
import type { ReadResult } from './result';

export function readNewline(cursor: Cursor): ReadResult<string> {
  if (startsWith(cursor, SpecialCharacters.carriageReturnLineFeed)) {
    return advance(cursor, SpecialCharacters.carriageReturnLineFeed.length);
  } else if (current(cursor) === SpecialCharacters.lineFeed) {
    return advance(cursor, SpecialCharacters.lineFeed.length);
  } else {
    return advance(cursor, SpecialCharacters.carriageReturn.length);
  }
}

export function readContinuation(cursor: Cursor): ReadResult<string> {
  return advance(cursor, SpecialCharacters.backslashLineFeed.length);
}
