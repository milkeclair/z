import { List } from 'immutable';
import { loop, again, done } from '../../../../util/loop';
import type { StringLiteralNode, WordPartNode } from '../../../ast';
import { rangeWithinText } from '../../range';
import { readExpansion } from './expansion';
import type { WordPartState, WordSegment } from './types';

export { wordSegmentFromToken } from './types';
export type { WordSegment } from './types';

export function createWordParts(segment: WordSegment): readonly WordPartNode[] {
  const initial: WordPartState = {
    ...segment,
    index: segment.start,
    literalStart: segment.start,
    quote: 'none',
    parts: List(),
  };

  const state = loop(initial, (current) =>
    current.index < current.end ? again(readWordPart(current)) : done(current),
  );
  return appendLiteralIfNeeded(state).toArray();
}

function readWordPart(state: WordPartState): WordPartState {
  const literalEnd = state.literalEnds?.get(state.index);
  if (literalEnd !== undefined) {
    return { ...state, index: Math.min(literalEnd, state.end) };
  }
  const char = state.text[state.index];

  if (isEscape(state)) {
    return { ...state, index: Math.min(state.index + 2, state.end) };
  } else if (state.quote === 'single' || state.quote === 'dollarSingle') {
    return {
      ...state,
      index: state.index + 1,
      quote: char === "'" ? 'none' : state.quote,
    };
  } else if (char === '"') {
    return {
      ...state,
      index: state.index + 1,
      quote: state.quote === 'double' ? 'none' : 'double',
    };
  } else if (state.quote === 'none' && char === "'") {
    return { ...state, index: state.index + 1, quote: 'single' };
  } else if (state.quote === 'none' && state.text.startsWith("$'", state.index)) {
    return { ...state, index: state.index + 2, quote: 'dollarSingle' };
  } else {
    return readExpansionPart(state);
  }
}

function readExpansionPart(state: WordPartState): WordPartState {
  const expansion = readExpansion(state);

  if (expansion) {
    return {
      ...state,
      index: expansion.nextIndex,
      literalStart: expansion.nextIndex,
      parts: appendLiteralBeforeExpansion(state).push(expansion.node),
    };
  } else {
    return { ...state, index: state.index + 1 };
  }
}

function isEscape(state: WordPartState): boolean {
  if (state.text[state.index] !== '\\' || state.quote === 'single') {
    return false;
  } else if (state.quote === 'double') {
    const next = state.text[state.index + 1];

    return next === '$' || next === '`' || next === '"' || next === '\\' || next === '\n';
  } else {
    return true;
  }
}

function appendLiteralIfNeeded(state: WordPartState): List<WordPartNode> {
  if (state.literalStart < state.index || state.parts.size === 0) {
    return state.parts.push(
      createStringLiteralNode({
        ...state,
        start: state.literalStart,
        end: state.index,
      }),
    );
  } else {
    return state.parts;
  }
}

function appendLiteralBeforeExpansion(state: WordPartState): List<WordPartNode> {
  if (state.literalStart < state.index) {
    return state.parts.push(
      createStringLiteralNode({
        ...state,
        start: state.literalStart,
        end: state.index,
      }),
    );
  } else {
    return state.parts;
  }
}

function createStringLiteralNode(segment: WordSegment): StringLiteralNode {
  return {
    kind: 'stringLiteral',
    range: rangeWithinText(segment.range, segment.text, segment.start, segment.end),
    value: segment.text.slice(segment.start, segment.end),
  };
}
