import { Func } from '../../getFunctions/type';
import { TEST_DSL_FUNCTIONS } from './constant';
import { requiredPositionalArgs } from '../argument';

export function isInsideQuoteFunctionCall(line: string, position: number): boolean {
  let inQuote = false;
  let quoteChar = '';

  const isEscapedQuote = (i: number): boolean => {
    const lastCharIndex = i - 1;

    return i > 0 && line[lastCharIndex] === '\\';
  };

  for (let i = 0; i < position; i++) {
    const char = line[i];

    if (!inQuote && (char === '"' || char === "'")) {
      inQuote = true;
      quoteChar = char;
    } else if (inQuote && char === quoteChar && !isEscapedQuote(i)) {
      inQuote = false;
      quoteChar = '';
    }
  }

  return inQuote;
}

export function isQuoteChar(char: string): boolean {
  return char === '"' || char === "'";
}

export function shouldSkipArgumentCheck(func: Func, functionName: string): boolean {
  return func.args.length === 0 && TEST_DSL_FUNCTIONS.includes(functionName as any);
}

export function hasAllRequiredPositionalArgs(
  func: Func,
  providedPositionalArgs: string[]
): boolean {
  return providedPositionalArgs.length >= requiredPositionalArgs(func).length;
}
