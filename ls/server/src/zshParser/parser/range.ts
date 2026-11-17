import { numberRange, takeWhile } from '../../util/collections';
import type { SourcePosition, SourceRange, Token } from '../lexer';

const Empty = '';
const LineFeed = '\n';
const CarriageReturn = '\r';

export const ZeroPosition: SourcePosition = {
  offset: 0,
  line: 0,
  character: 0,
};

const ZeroRange: SourceRange = {
  start: ZeroPosition,
  end: ZeroPosition,
};

export function rangeFromTokens(
  tokens: readonly Token[],
  fallback: SourceRange = ZeroRange,
): SourceRange {
  const first = tokens[0];
  const last = tokens[tokens.length - 1];

  if (first && last) {
    return {
      start: first.range.start,
      end: last.range.end,
    };
  } else {
    return fallback;
  }
}

export function rangeWithinToken(
  token: Token,
  startOffsetInToken: number,
  endOffsetInToken: number,
): SourceRange {
  return rangeWithinText(token.range, token.value, startOffsetInToken, endOffsetInToken);
}

export function areAdjacentTokens(left: Token, right: Token): boolean {
  return left.range.end.offset === right.range.start.offset;
}

export function rangeWithinText(
  range: SourceRange,
  text: string,
  startOffset: number,
  endOffset: number,
): SourceRange {
  return {
    start: positionAfterText({
      position: range.start,
      text: text.slice(0, startOffset),
    }),
    end: positionAfterText({
      position: range.start,
      text: text.slice(0, endOffset),
    }),
  };
}

function positionAfterText({
  position,
  text,
}: {
  readonly position: SourcePosition;
  readonly text: string;
}): SourcePosition {
  return numberRange(0, text.length).reduce((current, index) => {
    const char = text[index] ?? Empty;
    const nextChar = text[index + 1] ?? Empty;
    const newLine = char === LineFeed || (char === CarriageReturn && nextChar !== LineFeed);

    return {
      offset: current.offset + 1,
      line: newLine ? current.line + 1 : current.line,
      character: newLine ? 0 : current.character + 1,
    };
  }, position);
}

export function enclosingRange(
  range: SourceRange,
  children: readonly {
    readonly range: SourceRange;
  }[],
): SourceRange {
  const end = children.reduce(
    (previous, child) => (child.range.end.offset > previous.offset ? child.range.end : previous),
    range.end,
  );

  return { start: range.start, end };
}

export function textForRange(tokens: readonly Token[], range: SourceRange): string {
  return takeWhile(
    Iterator.from(tokens).filter((token) => token.range.end.offset > range.start.offset),
    (token) => token.range.start.offset < range.end.offset,
  )
    .map((token) =>
      token.value.slice(
        Math.max(0, range.start.offset - token.range.start.offset),
        Math.min(token.value.length, range.end.offset - token.range.start.offset),
      ),
    )
    .toArray()
    .join('');
}
