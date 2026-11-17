export type QuoteState = {
  readonly inQuote: boolean;
  readonly quoteChar: string;
  readonly beforeQuote: string;
  readonly wasQuoted: boolean;
  readonly hadQuotedValue: boolean;
  startOfQuote(char: string): boolean;
  handleStartOfQuote(char: string, current: string): void;
  endOfQuote(char: string): boolean;
  handleEndOfQuote(): void;
  endOfArgument(char: string): boolean;
  handleEndOfArgument(): void;
  endOfAllArguments(current: string): boolean;
};

export type DiagnosticRange = {
  readonly startChar: number;
  readonly endChar: number;
  readonly lineIndex: number;
};
