import type {
  StringLiteralNode,
  WordNode,
  WordPartNode,
} from '../../ast';
import type { SourceRange } from '../../lexer';
import { rangeWithinText } from '../range';

export function createWordNodeFromWordSlice({
  word,
  start,
  end,
}: {
  readonly word: WordNode;
  readonly start: number;
  readonly end: number;
}): WordNode {
  const parts = sliceWordParts({
    parts: word.parts,
    index: 0,
    rawOffset: 0,
    start,
    end,
    collected: [],
  });
  const raw = parts.map(rawFromWordPart).join('');

  return {
    kind: 'word',
    range: rangeFromWordParts(parts) ?? rangeWithinText(word.range, word.raw, start, end),
    raw,
    quoted: word.quoted,
    quoteKind: word.quoteKind,
    parts,
  };
}

function sliceWordParts({
  parts,
  index,
  rawOffset,
  start,
  end,
  collected,
}: {
  readonly parts: readonly WordPartNode[];
  readonly index: number;
  readonly rawOffset: number;
  readonly start: number;
  readonly end: number;
  readonly collected: readonly WordPartNode[];
}): readonly WordPartNode[] {
  const result = [...collected];
  let offset = rawOffset;
  for (let cursor = index; cursor < parts.length && offset < end; cursor += 1) {
    const part = parts[cursor];
    const length = rawFromWordPart(part).length;
    const sliced = sliceWordPart({ part, start: Math.max(start, offset) - offset, end: Math.min(end, offset + length) - offset });
    if (sliced) result.push(sliced);
    offset += length;
  }
  return result;
}

function sliceWordPart({
  part,
  start,
  end,
}: {
  readonly part: WordPartNode;
  readonly start: number;
  readonly end: number;
}): WordPartNode | null {
  const raw = rawFromWordPart(part);

  if (end <= start) {
    return null;
  } else if (start === 0 && end === raw.length) {
    return part;
  } else if (part.kind === 'stringLiteral') {
    return {
      kind: 'stringLiteral',
      range: rangeWithinText(part.range, part.value, start, end),
      value: part.value.slice(start, end),
    };
  } else {
    return {
      kind: 'stringLiteral',
      range: rangeWithinText(part.range, raw, start, end),
      value: raw.slice(start, end),
    } satisfies StringLiteralNode;
  }
}

function rangeFromWordParts(parts: readonly WordPartNode[]): SourceRange | null {
  const first = parts[0];
  const last = parts[parts.length - 1];

  if (!first || !last) {
    return null;
  } else {
    return {
      start: first.range.start,
      end: last.range.end,
    };
  }
}

function rawFromWordPart(part: WordPartNode): string {
  if (part.kind === 'stringLiteral') {
    return part.value;
  } else if (part.kind === 'variableReference') {
    return `${part.sigil}${part.name.value}`;
  } else {
    return part.raw;
  }
}
