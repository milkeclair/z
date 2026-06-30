import { Func, FuncArg } from '../getFunctions/type';
import { definedNamedArgs, parseArguments } from '../diagnostics/argument';
import { isInsideQuoteFunctionCall } from '../diagnostics/functionCall/matcher';

type CallContext = {
  func: Func;
  argsText: string;
};

const functionCallRegex = /\b(z(?:\.\w+)+\??)/g;
const namedArgTokenRegex = /^([a-zA-Z_][a-zA-Z0-9_]*)(?:=|$)/;
const commandBoundaryOperators = ['&&', '||', '>>', ';', '|', '>', '<'] as const;
const commandStartOperators = ["&&", "||", ";", "|"] as const;

function trailingWhitespace(text: string): boolean {
  return /\s$/.test(text);
}

function currentToken(text: string): string {
  let start = text.length;
  let inQuote = false;
  let quoteChar = '';

  for (let i = text.length - 1; i >= 0; i--) {
    const char = text[i];

    if ((char === '"' || char === "'") && (i === 0 || text[i - 1] !== '\\')) {
      if (!inQuote) {
        inQuote = true;
        quoteChar = char;
      } else if (quoteChar === char) {
        inQuote = false;
        quoteChar = '';
      }
    }

    if (!inQuote && /\s/.test(char)) break;
    start = i;
  }

  return text.substring(start);
}

function namedArgIndex(func: Func, token: string): number {
  const match = token.match(namedArgTokenRegex);
  if (!match) return -1;

  const name = match[1];
  return func.args.findIndex((arg) => arg.isNamed && arg.name === name);
}

function positionalArgIndex(func: Func, zeroBasedPosition: number): number {
  const position = zeroBasedPosition + 1;

  return func.args.findIndex((arg) => !arg.isNamed && arg.position === position);
}

function restArgIndex(func: Func): number {
  return func.args.findIndex((arg) => !arg.isNamed && arg.name === '@');
}

function firstAvailableNamedArgIndex(func: Func, usedNamedArgs: Map<string, string>): number {
  return func.args.findIndex((arg) => arg.isNamed && !usedNamedArgs.has(arg.name));
}

function hasCommandBoundary(text: string): boolean {
  let inQuote = false;
  let quoteChar = '';

  for (let i = 0; i < text.length; i++) {
    const char = text[i];

    if ((char === '"' || char === "'") && (i === 0 || text[i - 1] !== '\\')) {
      if (!inQuote) {
        inQuote = true;
        quoteChar = char;
      } else if (quoteChar === char) {
        inQuote = false;
        quoteChar = '';
      }
    }

    if (inQuote) continue;
    if (commandBoundaryOperators.some((operator) => text.startsWith(operator, i))) return true;
  }

  return false;
}

function isAtCommandPosition(textBeforeFunction: string): boolean {
  let inQuote = false;
  let quoteChar = "";
  let lastBoundaryEnd = 0;

  for (let i = 0; i < textBeforeFunction.length; i++) {
    const char = textBeforeFunction[i];
    const isQuote = char.charCodeAt(0) === 34 || char.charCodeAt(0) === 39;
    const isEscaped = i > 0 && textBeforeFunction.charCodeAt(i - 1) === 92;

    if (isQuote && !isEscaped) {
      if (!inQuote) {
        inQuote = true;
        quoteChar = char;
      } else if (quoteChar === char) {
        inQuote = false;
        quoteChar = "";
      }
    }

    if (inQuote) continue;

    const operator = commandStartOperators.find((candidate) =>
      textBeforeFunction.startsWith(candidate, i),
    );
    if (!operator) continue;

    lastBoundaryEnd = i + operator.length;
    i += operator.length - 1;
  }

  return textBeforeFunction.substring(lastBoundaryEnd).trim() === "";
}

export function findCallContext(lineBeforeCursor: string, functions: Func[]): CallContext | null {
  functionCallRegex.lastIndex = 0;
  let context: CallContext | null = null;
  let match: RegExpExecArray | null;

  while ((match = functionCallRegex.exec(lineBeforeCursor)) !== null) {
    const functionName = match[1];
    const func = functions.find((f) => f.name === functionName);
    if (!func) continue;

    const startChar = match.index;
    const endChar = startChar + functionName.length;
    const nextChar = lineBeforeCursor[endChar] ?? '';

    if (nextChar !== '' && !/\s/.test(nextChar)) continue;
    if (!isAtCommandPosition(lineBeforeCursor.substring(0, startChar))) continue;
    if (isInsideQuoteFunctionCall(lineBeforeCursor, startChar)) continue;

    const argsText = lineBeforeCursor.substring(endChar);
    if (hasCommandBoundary(argsText)) {
      context = null;
      continue;
    }

    context = {
      func,
      argsText,
    };
  }

  functionCallRegex.lastIndex = 0;
  return context;
}

export function activeParameterIndex(func: Func, argsText: string): number | null {
  if (func.args.length === 0) return null;
  if (argsText.trim() === '') return 0;

  const token = currentToken(argsText);
  const namedIndex = namedArgIndex(func, token);
  if (namedIndex >= 0) return namedIndex;

  const { positional, named } = parseArguments(argsText, definedNamedArgs(func));
  const currentPositionalIndex = trailingWhitespace(argsText)
    ? positional.length
    : Math.max(positional.length - 1, 0);
  const positionalIndex = positionalArgIndex(func, currentPositionalIndex);
  if (positionalIndex >= 0) return positionalIndex;

  const restIndex = restArgIndex(func);
  if (restIndex >= 0 && (positional.length > 0 || trailingWhitespace(argsText))) return restIndex;

  const namedCandidateIndex = firstAvailableNamedArgIndex(func, named);
  if (namedCandidateIndex >= 0) return namedCandidateIndex;

  if (restIndex >= 0) return restIndex;

  return null;
}

export function activeParameter(func: Func, argsText: string): FuncArg | null {
  if (func.args.length === 0) return null;

  const index = activeParameterIndex(func, argsText);
  if (index === null) return null;

  return func.args[index] ?? null;
}
