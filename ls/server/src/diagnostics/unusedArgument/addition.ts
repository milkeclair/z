import { Diagnostics } from '../type';
import { DiagnosticSeverity } from '../../vscode_type';
import { FuncArg } from '../../getFunctions/type';
import { argDisplayName } from './argument';

export function addUnusedArgDiagnostic(
  diagnostics: Diagnostics[],
  line: string,
  lineIndex: number,
  arg: FuncArg,
  funcName: string
): void {
  diagnostics.push({
    severity: DiagnosticSeverity.Warning,
    range: {
      start: { line: lineIndex, character: 0 },
      end: { line: lineIndex, character: line.length },
    },
    message: `Argument '${argDisplayName(arg)}' is never used.`,
    source: 'zls',
  });
}
