import { Range } from 'immutable';
import { again, done, loop } from '../../../util/loop';
import type { VariableNameNode } from '../../ast';
import type { SourceRange } from '../../lexer';

const Empty = '';
const Underscore = '_';

export function createVariableNameNode({
  value,
  range,
}: {
  readonly value: string;
  readonly range: SourceRange;
}): VariableNameNode {
  return {
    kind: 'variableName',
    range,
    value,
  };
}

export function readNameEnd({
  value,
  index,
  max,
}: {
  readonly value: string;
  readonly index: number;
  readonly max: number;
}): number {
  return loop(index, (cursor) =>
    cursor < max && isNamePart(value[cursor] ?? Empty) ? again(cursor + 1) : done(cursor),
  );
}

export function isNameStart(char: string): boolean {
  return char === Underscore || isAsciiLetter(char);
}

export function isVariableName(value: string): boolean {
  return value.length > 0 && isNameStart(value[0] ?? Empty) && isNameTail(value, 1);
}

function isNameTail(value: string, index: number): boolean {
  return Range(index, value.length).every((cursor) => isNamePart(value[cursor]));
}

function isNamePart(char: string): boolean {
  return isNameStart(char) || isAsciiDigit(char);
}

function isAsciiLetter(char: string): boolean {
  return (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z');
}

function isAsciiDigit(char: string): boolean {
  return char >= '0' && char <= '9';
}
