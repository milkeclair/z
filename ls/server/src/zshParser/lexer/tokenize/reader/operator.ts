import type { OperatorDefinition } from '../../character';
import { advance, position } from '../../cursor';
import type { Cursor } from '../../cursor';
import type { Token } from '../../token';
import { createToken } from '../../token';
import type { ReadResult } from './result';

type OperatorReadContext = {
  readonly sourceFile: string;
  readonly cursor: Cursor;
  readonly operator: OperatorDefinition;
};

export function readOperator({
  sourceFile,
  cursor,
  operator,
}: OperatorReadContext): ReadResult<Token> {
  const start = position(cursor);
  const result = advance(cursor, operator.value.length);

  return {
    value: createToken({
      kind: 'operator',
      value: result.value,
      sourceFile,
      start,
      end: position(result.cursor),
      operatorKind: operator.kind,
    }),
    cursor: result.cursor,
  };
}
