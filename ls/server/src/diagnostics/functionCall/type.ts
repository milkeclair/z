export type QuoteState = {
  inQuote: boolean;
  quoteChar: string;
  beforeQuote: string;
  wasQuoted: boolean;
  hadQuotedValue: boolean;
  startOfQuote(char: string): boolean;
  handleStartOfQuote(char: string, current: string): void;
  endOfQuote(char: string): boolean;
  handleEndOfQuote(): void;
  endOfArgument(char: string): boolean;
  handleEndOfArgument(): void;
  endOfAllArguments(current: string): boolean;
};

export type DiagnosticRange = {
  startChar: number;
  endChar: number;
  lineIndex: number;
};
