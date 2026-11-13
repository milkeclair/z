import type { WordContext } from './part/types';
import type { WordNode } from '../../ast';
import type { Token } from '../../lexer';
import { rangeWithinText } from '../range';
import type { WordSegment } from './part';
import { createWordParts, wordSegmentFromToken } from './part';

export {
  isAssignmentPrefix,
  readAssignmentSyntax,
} from './assignmentPrefix';
export type { AssignmentSyntax } from './assignmentPrefix';
export {
  createVariableNameNode,
  isVariableName,
} from './variableName';
export { createWordNodeFromWordSlice } from './slice';

export function createWordNode(token: Token, context: WordContext = {}): WordNode {
  return createWordNodeFromTokenSegment({
    token,
    ...context,
    start: 0,
    end: token.value.length,
  });
}

function createWordNodeFromTokenSegment({
  token,
  start,
  end,
  ...context
}: WordContext & {
  readonly token: Token;
  readonly start: number;
  readonly end: number;
}): WordNode {
  return createWordNodeFromTextSegment({ ...createTokenWordSegment({ token, start, end }), ...context });
}

function createWordNodeFromTextSegment(segment: WordSegment): WordNode {
  const raw = segment.text.slice(segment.start, segment.end);

  return {
    kind: 'word',
    range: rangeWithinText(segment.range, segment.text, segment.start, segment.end),
    raw,
    quoted: segment.quoted,
    quoteKind: segment.quoteKind,
    parts: createWordParts(segment),
  };
}

function createTokenWordSegment({
  token,
  start,
  end,
}: {
  readonly token: Token;
  readonly start: number;
  readonly end: number;
}): WordSegment {
  return wordSegmentFromToken({
    token,
    start,
    end,
  });
}
