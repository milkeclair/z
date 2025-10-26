import { DiagnosticSeverity } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { findClosestMatch } from '../util/levenshtein';

export function handleExistingFunctionCall(
  functions: Func[],
  functionName: string,
  startChar: number,
  endChar: number,
  lineIndex: number,
  diagnostics: Diagnostics[]
) {
  const funcExists = functions.some((f) => f.name === functionName);

  if (!funcExists) {
    const functionNames = functions.map((f) => f.name);
    const suggestion = findClosestMatch(functionName, functionNames);

    const message = suggestion
      ? `${functionName} is not defined. <${suggestion}>?`
      : `${functionName} is not defined.`;

    diagnostics.push({
      severity: DiagnosticSeverity.Error,
      range: {
        start: { line: lineIndex, character: startChar },
        end: { line: lineIndex, character: endChar },
      },
      message,
      source: 'z-ls',
    });
  }
}
