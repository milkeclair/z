import { tokenize } from './tokenize';

export const Lexer = {
  tokenize,
};

export { advance, createCursor, current, eof, position, startsWith } from './cursor';
export type { Cursor } from './cursor';
export type { LexerDiagnostic } from './diagnostic';
export type {
  OperatorKind,
  QuoteKind,
  SourcePosition,
  SourceRange,
  Token,
  TokenizeOptions,
} from './token';
export type { TokenizeResult } from './tokenize';
