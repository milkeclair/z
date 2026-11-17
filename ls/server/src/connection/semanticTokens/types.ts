export const codeTokenTypes = [
  'function',
  'variable',
  'parameter',
  'keyword',
  'string',
  'comment',
  'number',
  'operator',
] as const;
export type TokenType = (typeof codeTokenTypes)[number];
export type Span = {
  readonly start: number;
  readonly end: number;
  readonly type: TokenType;
  readonly priority: number;
};
export const MAX_HIGHLIGHT_SPANS = 32768;
