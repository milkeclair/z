import { Diagnostics } from './type';
import { Func } from '../getFunctions/type';
import { findFunctionDefinition, findFunctionEnd } from './unusedArgument/function';
import { isArgumentUsedInFunction } from './unusedArgument/matcher';
import { argName, findArgDefinitionLine } from './unusedArgument/argument';
import { addUnusedArgDiagnostic } from './unusedArgument/addition';

export function checkUnusedArguments(
  lines: string[],
  func: Func,
  diagnostics: Diagnostics[]
): void {
  const funcDefLine = findFunctionDefinition(lines, func.name);
  const notFound = funcDefLine === -1;
  if (notFound) return;

  const funcEndLine = findFunctionEnd(lines, funcDefLine);

  func.args.forEach((arg) => {
    const isUsed = isArgumentUsedInFunction(lines, argName(arg), funcDefLine, funcEndLine);

    if (!isUsed) {
      const argDefLine = findArgDefinitionLine(lines, arg, funcDefLine);
      const notFoundArgDef = argDefLine === -1;
      if (notFoundArgDef) return;

      addUnusedArgDiagnostic(diagnostics, lines[argDefLine], argDefLine, arg, func.name);
    }
  });
}
