import type { Token } from '../lexer';

export function isCommandBoundary(token: Token): boolean {
  return (
    token.kind === 'eof' ||
    token.kind === 'newline' ||
    token.operatorKind === 'semicolon' ||
    token.operatorKind === 'background' ||
    token.operatorKind === 'backgroundPipe' ||
    token.operatorKind === 'backgroundBang' ||
    token.operatorKind === 'andIf' ||
    token.operatorKind === 'orIf' ||
    token.operatorKind === 'pipe' ||
    token.operatorKind === 'pipeErr' ||
    token.operatorKind === 'rightBrace' ||
    token.operatorKind === 'rightParen' ||
    token.operatorKind === 'doubleSemicolon' ||
    token.operatorKind === 'caseFallthrough' ||
    token.operatorKind === 'caseContinue'
  );
}
