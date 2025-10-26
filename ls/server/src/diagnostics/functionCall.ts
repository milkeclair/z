import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { shouldSkipArgumentCheck, hasAllRequiredPositionalArgs } from './functionCall/matcher';
import { FunctionDiagnostics } from './functionCall/addition';
import {
  definedNamedArgs,
  isMissingNamedArg,
  requiredPositionalArgs,
  requiredNamedArgs,
  parseArguments,
} from './argument';

export function handleFunctionCall(
  functions: Func[],
  functionName: string,
  argsText: string,
  startChar: number,
  endChar: number,
  lineIndex: number,
  diagnostics: Diagnostics[]
): void {
  const func = functions.find((f) => f.name === functionName);
  const funcDiag = FunctionDiagnostics(startChar, endChar, lineIndex, diagnostics);

  if (!func) {
    const functionNames = functions.map((f) => f.name);
    funcDiag.addUndefined(functionName, functionNames);
    return;
  }

  if (shouldSkipArgumentCheck(func, functionName)) return;

  const { positional, named } = parseArguments(argsText, definedNamedArgs(func));

  if (!hasAllRequiredPositionalArgs(func, positional)) {
    const missingArgs = requiredPositionalArgs(func).slice(positional.length);
    funcDiag.addMissingPositionalArgs(missingArgs);
  }

  for (const arg of requiredNamedArgs(func)) {
    if (isMissingNamedArg(named, arg)) {
      funcDiag.addMissingNamedArg(arg.name);
    }
  }
}
