import type { WordNode } from '../word';
import { hereDocDelimiter } from '../../lexer/delimiter';

/** 静的な単語または接頭辞を復号し、展開を含む値は動的なまま扱う。 */
export function literalWord(word: WordNode, end = word.raw.length): string | null {
  if (word.parts.some((part) => part.kind !== 'stringLiteral')) return null;
  return hereDocDelimiter(word.raw.slice(0, end)).delimiter;
}

/** 展開を評価せずにシェルの引用を外し、単語の静的な接頭辞から名前付き引数のキーを読む。 */
export function namedKey(word: WordNode): string | null {
  const prefix = word.parts[0];

  if (prefix?.kind !== 'stringLiteral') {
    return null;
  }

  const text = hereDocDelimiter(prefix.value).delimiter;

  return /^([_a-zA-Z][_a-zA-Z0-9]*)=/.exec(text)?.[1] ?? null;
}
