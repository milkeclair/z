import type { WordNode } from './word';
import { hereDocDelimiter } from '../../lexer/delimiter';

/** Decode a literal word or prefix; expansions keep their dynamic meaning. */
export function literalWord(word: WordNode, end = word.raw.length): string | null {
  if (word.parts.some(part => part.kind !== 'stringLiteral')) return null;
  return hereDocDelimiter(word.raw.slice(0, end)).delimiter;
}
