import type { EofNode } from '../../ast';
import type { Token } from '../../lexer';

export function createEofNode(token: Token): EofNode {
  return {
    kind: 'eof',
    range: token.range,
  };
}
