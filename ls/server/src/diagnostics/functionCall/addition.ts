import { DiagnosticSeverity } from 'vscode-languageserver';
import { FuncArg } from '../../getFunctions/type';
import { Diagnostics } from '../type';
import { DiagnosticRange } from './type';
import { findClosestMatch } from '../../util/levenshtein';

function createDiagnostic(
  range: DiagnosticRange,
  message: string,
  diagnostics: Diagnostics[]
): void {
  diagnostics.push({
    severity: DiagnosticSeverity.Error,
    range: {
      start: { line: range.lineIndex, character: range.startChar },
      end: { line: range.lineIndex, character: range.endChar },
    },
    message,
    source: 'z-ls',
  });
}

export function FunctionDiagnostics(
  startChar: number,
  endChar: number,
  lineIndex: number,
  diagnostics: Diagnostics[]
) {
  const range: DiagnosticRange = { startChar, endChar, lineIndex };

  return {
    addUndefined: (functionName: string, functionNames: string[]) => {
      const suggestion = findClosestMatch(functionName, functionNames);
      const message = suggestion
        ? `${functionName} is not defined. <${suggestion}>?`
        : `${functionName} is not defined.`;

      createDiagnostic(range, message, diagnostics);
    },

    addMissingPositionalArgs: (missingArgs: FuncArg[]) => {
      const missingArgNames = missingArgs.map((arg) => `$${arg.position}`).join(', ');
      const message = `Missing required argument(s): ${missingArgNames}`;

      createDiagnostic(range, message, diagnostics);
    },

    addMissingNamedArg: (argName: string) => {
      const message = `Missing required named argument: ${argName}`;

      createDiagnostic(range, message, diagnostics);
    },
  };
}
