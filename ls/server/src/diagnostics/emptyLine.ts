import { DiagnosticSeverity } from '../vscode_type';
import { Diagnostics } from './type';

function handleFirstEmptyLine(lines: string[], diagnostics: Diagnostics[]) {
  if (lines.length > 0 && lines[0].trim() === '') {
    diagnostics.push({
      severity: DiagnosticSeverity.Warning,
      range: {
        start: { line: 0, character: 0 },
        end: { line: 0, character: lines[0].length },
      },
      message: 'File starts with an empty line.',
      source: 'z-ls',
    });
  }
}

function handleEmptyLine(line: string, lineIndex: number, diagnostics: Diagnostics[]) {
  if (line.trim() === '' && line.length > 0) {
    diagnostics.push({
      severity: DiagnosticSeverity.Warning,
      range: {
        start: { line: lineIndex, character: 0 },
        end: { line: lineIndex, character: line.length },
      },
      message: 'Line contains only whitespace characters.',
      source: 'z-ls',
    });
  }
}

function handleFinalNewLine(text: string, diagnostics: Diagnostics[], totalLines: number) {
  if (!text.endsWith('\n')) {
    diagnostics.push({
      severity: DiagnosticSeverity.Warning,
      range: {
        start: { line: totalLines - 1, character: text.length },
        end: { line: totalLines - 1, character: text.length },
      },
      message: 'File does not end with a newline.',
      source: 'z-ls',
    });
  }
}

export { handleFirstEmptyLine, handleEmptyLine, handleFinalNewLine };
