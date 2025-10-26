import { Func, FuncArg } from '../getFunctions/type';
import { OPERATORS } from './functionCall/constant';
import { namedArgRegex } from './functionCall/regex';
import { initQuoteState } from './functionCall/state';

export function ArgsText(line: string, endChar: number): string {
  return line.substring(endChar).trim();
}

export function definedNamedArgs(func: Func): string[] {
  return func.args.filter((arg) => arg.isNamed).map((arg) => arg.name);
}

export function requiredPositionalArgs(func: Func): Func['args'] {
  return func.args.filter(
    (arg) => !arg.isNamed && !arg.optional && arg.position !== Number.MAX_SAFE_INTEGER
  );
}

export function requiredNamedArgs(func: Func): Func['args'] {
  return func.args.filter((arg) => arg.isNamed && !arg.optional);
}

export function isMissingNamedArg(
  namedArgs: Map<string, string>,
  requiredNamedArg: FuncArg
): boolean {
  return !namedArgs.has(requiredNamedArg.name);
}

function cutTextBeforeOperators(text: string): string {
  let cutText = text;

  for (const op of OPERATORS) {
    const index = text.indexOf(op);
    if (index === -1) continue;

    const beforeOp = text.substring(0, index);
    if (cutText === text || beforeOp.length < cutText.length) {
      cutText = beforeOp;
    }
  }

  return cutText;
}

function pushArgumentFromType(
  arg: string,
  positional: string[],
  named: Map<string, string>,
  hadQuotedValue: boolean,
  definedNamedArgs: string[]
): void {
  const namedMatch = arg.match(namedArgRegex);

  if (!namedMatch) {
    positional.push(arg);
    return;
  }

  const [, name, value] = namedMatch;

  // arg="" => named
  // "arg=" => positional
  if (value === '' && !hadQuotedValue) {
    positional.push(arg);
    return;
  }

  if (definedNamedArgs.includes(name)) {
    named.set(name, value);
  } else {
    positional.push(arg);
  }
}

export function parseArguments(
  argsText: string,
  definedNamedArgs: string[]
): { positional: string[]; named: Map<string, string> } {
  if (!argsText.trim()) {
    return { positional: [], named: new Map() };
  }

  const beforeOperators = cutTextBeforeOperators(argsText);
  const positional: string[] = [];
  const named = new Map<string, string>();
  const state = initQuoteState();
  let current = '';

  for (let i = 0; i < beforeOperators.length; i++) {
    const char = beforeOperators[i];

    if (state.startOfQuote(char)) {
      state.handleStartOfQuote(char, current);
      current = '';
    } else if (state.endOfQuote(char)) {
      current = state.beforeQuote + current;
      state.handleEndOfQuote();
    } else if (state.endOfArgument(char)) {
      const nonQuotedPresentArg = current.length > 0 && !state.wasQuoted;
      if (!nonQuotedPresentArg && !state.wasQuoted) continue;

      pushArgumentFromType(current, positional, named, state.hadQuotedValue, definedNamedArgs);
      state.handleEndOfArgument();
      current = '';
    } else {
      current += char;
    }
  }

  if (state.endOfAllArguments(current)) {
    pushArgumentFromType(current, positional, named, state.hadQuotedValue, definedNamedArgs);
  }

  return { positional, named };
}
