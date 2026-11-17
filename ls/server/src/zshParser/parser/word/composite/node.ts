import * as Immutable from 'immutable';
import type { WordNode } from '../../../ast';
import type { QuoteKind, Token } from '../../../lexer';
import { rangeFromTokens } from '../../range';
import { createWordParts } from '../part';
import type { WordContext } from '../part/types';

export function createCompositeWordNode(
  tokens: readonly Token[],
  context: WordContext = {},
): WordNode {
  const raw = tokens.map((token) => token.value).join('');
  const offsets = tokens.reduce(
    (previous, token) => {
      const end = previous.offset + token.value.length;

      return {
        offset: end,
        literalEnds:
          token.kind === 'comment' || token.kind === 'hereDocBody' || token.kind === 'hereDocEnd'
            ? previous.literalEnds.set(previous.offset, end)
            : previous.literalEnds,
        processStarts:
          token.kind === 'word' && token.value === '='
            ? previous.processStarts.add(previous.offset)
            : previous.processStarts,
      };
    },
    {
      offset: 0,
      literalEnds: Immutable.Map<number, number>(),
      processStarts: Immutable.Set<number>(),
    },
  );
  const literalEnds = new Map(offsets.literalEnds);
  const processStarts = new Set(offsets.processStarts);

  return {
    kind: 'word',
    range: rangeFromTokens(tokens),
    raw,
    quoted: tokens.some((token) => token.quoted),
    quoteKind: compositeQuoteKind(tokens),
    parts: createWordParts({
      literalEnds,
      processStarts,
      ...context,
      text: raw,
      range: rangeFromTokens(tokens),
      start: 0,
      end: raw.length,
      quoted: tokens.some((token) => token.quoted),
      quoteKind: compositeQuoteKind(tokens),
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
