import type { WordNode } from '../word';
import { hereDocDelimiter } from '../../lexer/delimiter';

/** 静的な単語または接頭辞を復号し、展開を含む値は動的なまま扱う。 */
export function literalWord(word: WordNode, end = word.raw.length): string | null {
  if (word.parts.some((part) => part.kind !== 'stringLiteral')) return null;
  return hereDocDelimiter(word.raw.slice(0, end)).delimiter;
}
