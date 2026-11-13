import { parse } from './parse';

export const Parser = {
  parse,
};

export { tokenAtOffset, tokensInRange } from './tokenTable';
export type { ParseOptions, ParseResult, ParserDiagnostic } from './parse';
