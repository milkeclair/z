import { current } from '../cursor';
import type { Cursor } from '../cursor';
import { findOperator, isHorizontalWhitespace, isNewline } from './predicate';

export function isWordBoundary(cursor: Cursor): boolean {
  return (
    isHorizontalWhitespace(current(cursor)) ||
    isNewline(cursor) ||
    findOperator(cursor) !== null
  );
}
