import type { WordContext } from '../part/types';
import type { WordNode } from '../../../ast';
import type { QuoteKind, Token } from '../../../lexer';
import { rangeFromTokens } from '../../range';
import { createWordParts } from '../part';

export function createCompositeWordNode(tokens: readonly Token[], context: WordContext = {}): WordNode {
  const raw = tokens.map((token) => token.value).join('');
  const literalEnds = new Map<number, number>();
  const processStarts = new Set<number>();
  let offset = 0;
  for (const token of tokens) {
    if (token.kind === 'word' && token.value === '=') processStarts.add(offset);
    if (token.kind === 'comment' || token.kind === 'hereDocBody' || token.kind === 'hereDocEnd') literalEnds.set(offset, offset + token.value.length);
    offset += token.value.length;
  }

  return {
    kind: 'word',
    range: rangeFromTokens(tokens),
    raw,
    quoted: tokens.some((token) => token.quoted),
    quoteKind: compositeQuoteKind(tokens),
    parts: createWordParts({
      literalEnds, processStarts,
      ...context,
      text: raw, range: rangeFromTokens(tokens), start: 0, end: raw.length,
      quoted: tokens.some((token) => token.quoted), quoteKind: compositeQuoteKind(tokens),
    }),
  };
}

function compositeQuoteKind(tokens: readonly Token[]): QuoteKind {
  const quoted = tokens.filter((token) => token.quoteKind !== 'none');
  const first = quoted[0];

  if (!first) {
    return 'none';
  } else if (quoted.every((token) => token.quoteKind === first.quoteKind)) {
    return first.quoteKind;
  } else {
    return 'mixed';
  }
}
