import { parse } from './parse';

export const Parser = {
  parse,
};

export type { ParseOptions, ParserDiagnostic, ParseResult } from './parse';
export { tokenAtOffset, tokensInRange } from './tokenTable';
