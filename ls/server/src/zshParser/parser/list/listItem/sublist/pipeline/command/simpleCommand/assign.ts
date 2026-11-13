import type {
  AssignNode,
  VariableValueNode,
  WordNode,
} from '../../../../../../../ast';
import { rangeWithinText } from '../../../../../../range';
import {
  createWordNodeFromWordSlice,
  createVariableNameNode,
  readAssignmentSyntax,
} from '../../../../../../word';

export function createAssignNodeFromWord(word: WordNode): AssignNode | null {
  const parts = readAssignmentSyntax(word.raw);

  if (!parts) {
    return null;
  } else {
    const name = createVariableNameNode({
      value: word.raw.slice(parts.nameStart, parts.nameEnd),
      range: rangeWithinText(word.range, word.raw, parts.nameStart, parts.nameEnd),
    });
    const subscript = createSubscriptWordNode({
      word,
      start: parts.subscriptStart,
      end: parts.subscriptEnd,
    });
    const value = createVariableValueNode({
      word,
      start: parts.valueStart,
      end: parts.valueEnd,
    });

    return {
      kind: 'assign',
      range: word.range,
      name,
      subscript,
      operator: parts.operator,
      value,
    };
  }
}

function createSubscriptWordNode({
  word,
  start,
  end,
}: {
  readonly word: WordNode;
  readonly start: number | null;
  readonly end: number | null;
}): WordNode | null {
  if (start === null || end === null) {
    return null;
  } else {
    return createWordNodeFromWordSlice({
      word,
      start,
      end,
    });
  }
}

function createVariableValueNode({
  word,
  start,
  end,
}: {
  readonly word: WordNode;
  readonly start: number;
  readonly end: number;
}): VariableValueNode {
  const value = createWordNodeFromWordSlice({
    word,
    start,
    end,
  });

  return {
    kind: 'variableValue',
    range: value.range,
    value,
  };
}
