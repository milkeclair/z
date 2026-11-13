import type { SourceRange, Token } from '../../lexer';

export function tokensInRange(
  tokens: readonly Token[],
  range: SourceRange,
): readonly Token[] {
  return tokens.filter((token) => overlapsToken(range, token));
}

export function tokenAtOffset(
  tokens: readonly Token[],
  offset: number,
): Token | null {
  return tokens.find((token) => (
    token.range.start.offset <= offset &&
    offset < token.range.end.offset
  )) ?? null;
}

function overlapsToken(range: SourceRange, token: Token): boolean {
  return (
    range.start.offset < token.range.end.offset &&
    token.range.start.offset < range.end.offset
  );
}
