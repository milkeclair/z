import { SpecialCharacters } from '../../../character';

export type QuoteReadKind = 'single' | 'double' | 'dollarSingle';

export type QuoteDefinition = {
  readonly quoteKind: QuoteReadKind;
  readonly start: string;
  readonly end: string;
  readonly escapeBackslash: boolean;
};

export const SingleQuoteDefinition: QuoteDefinition = {
  quoteKind: 'single',
  start: SpecialCharacters.singleQuote,
  end: SpecialCharacters.singleQuote,
  escapeBackslash: false,
};

export const DoubleQuoteDefinition: QuoteDefinition = {
  quoteKind: 'double',
  start: SpecialCharacters.doubleQuote,
  end: SpecialCharacters.doubleQuote,
  escapeBackslash: true,
};

export const DollarSingleQuoteDefinition: QuoteDefinition = {
  quoteKind: 'dollarSingle',
  start: SpecialCharacters.dollarSingleQuoteStart,
  end: SpecialCharacters.singleQuote,
  escapeBackslash: true,
};
