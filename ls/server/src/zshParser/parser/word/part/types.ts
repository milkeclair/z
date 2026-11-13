import type { ListNode, WordPartNode } from '../../../ast';
import type { QuoteKind, SourceRange, Token } from '../../../lexer';

export type WordContext = {
  readonly readBody?: (raw: string, range: SourceRange) => ListNode | null;
};

export type WordSegment = WordContext & {
  readonly literalEnds?: ReadonlyMap<number, number>;
  readonly processStarts?: ReadonlySet<number>;
  readonly text: string;
  readonly range: SourceRange;
  readonly quoted: boolean;
  readonly quoteKind: QuoteKind;
  readonly start: number;
  readonly end: number;
};

export type WordPartState = WordSegment & {
  readonly index: number;
  readonly literalStart: number;
  readonly quote: 'none' | 'single' | 'double' | 'dollarSingle';
  readonly parts: readonly WordPartNode[];
};

export type ExpansionReadResult = {
  readonly node: WordPartNode;
  readonly nextIndex: number;
};

export function wordSegmentFromToken({
  token,
  start,
  end,
}: {
  readonly token: Token;
  readonly start: number;
  readonly end: number;
}): WordSegment {
  return {
    text: token.value,
    range: token.range,
    quoted: token.quoted,
    quoteKind: token.quoteKind,
    start,
    end,
  };
}
