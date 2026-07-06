import type { Cursor } from '../../cursor';

export type ReadResult<Value> = {
  readonly value: Value;
  readonly cursor: Cursor;
};
