import { QuoteState } from './type';
import { isQuoteChar } from './matcher';

export function initQuoteState(): QuoteState {
  return {
    inQuote: false,
    quoteChar: '',
    beforeQuote: '',
    wasQuoted: false,
    hadQuotedValue: false,

    startOfQuote(char: string): boolean {
      return !this.inQuote && isQuoteChar(char);
    },

    handleStartOfQuote(char: string, current: string): void {
      this.inQuote = true;
      this.quoteChar = char;
      this.beforeQuote = current;
      this.wasQuoted = true;
      this.hadQuotedValue = current.includes('=');
    },

    endOfQuote(char: string): boolean {
      return this.inQuote && char === this.quoteChar;
    },

    handleEndOfQuote(): void {
      this.inQuote = false;
      this.beforeQuote = '';
      this.quoteChar = '';
    },

    endOfArgument(char: string): boolean {
      return !this.inQuote && /[\s]/.test(char);
    },

    handleEndOfArgument(): void {
      this.wasQuoted = false;
      this.hadQuotedValue = false;
    },

    endOfAllArguments(current: string): boolean {
      return current.length > 0 || this.wasQuoted;
    },
  };
}
