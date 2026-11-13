import type { WordNode } from '../zshParser/ast';
import { hereDocDelimiter } from '../zshParser/lexer/delimiter';

export function literalWord(word: WordNode, end = word.raw.length): string | null {
  if (word.parts.some(part => part.kind !== 'stringLiteral')) return null;
  return hereDocDelimiter(word.raw.slice(0, end)).delimiter;
}
