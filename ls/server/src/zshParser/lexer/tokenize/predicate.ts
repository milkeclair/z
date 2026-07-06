import { Operators, SpecialCharacters } from '../character';
import type { OperatorDefinition } from '../character';
import { current, startsWith } from '../cursor';
import type { Cursor } from '../cursor';

export function isHorizontalWhitespace(char: string): boolean {
  return char === SpecialCharacters.space || char === SpecialCharacters.tab;
}

export function isNewline(cursor: Cursor): boolean {
  return (
    startsWith(cursor, SpecialCharacters.carriageReturnLineFeed) ||
    current(cursor) === SpecialCharacters.lineFeed ||
    current(cursor) === SpecialCharacters.carriageReturn
  );
}

export function isContinuation(cursor: Cursor): boolean {
  return startsWith(cursor, SpecialCharacters.backslashLineFeed);
}

export function findOperator(cursor: Cursor): OperatorDefinition | null {
  return Operators.find((operator) => startsWith(cursor, operator.value)) ?? null;
}
