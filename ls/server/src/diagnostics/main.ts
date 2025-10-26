import { DiagnosticSeverity, TextDocument } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { functionCallRegex, functionDefRegex } from './regex';
import { findClosestMatch } from '../util/levenshtein';

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

function handleExistingFunctionCall(
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

export function validateTextDocument({
  functions,
  textDocument,
}: {
  functions: Func[];
  textDocument: TextDocument;
}): Diagnostics[] {
  const text = textDocument.getText();
  const diagnostics: Diagnostics[] = [];
  const lines = text.split('\n');

  lines.forEach((line, lineIndex) => {
    const trimmedLine = line.trim();
    if (trimmedLine.startsWith('#')) return;
    if (line.includes('# zls: ignore')) return;
    if (functionDefRegex.test(line)) return;

    if (trimmedLine === '') {
      handleEmptyLine(line, lineIndex, diagnostics);
      return;
    }

    let match;
    while ((match = functionCallRegex.exec(line)) !== null) {
      const functionName = match[1];
      const startChar = match.index;
      const endChar = startChar + functionName.length;

      handleExistingFunctionCall(
        functions,
        functionName,
        startChar,
        endChar,
        lineIndex,
        diagnostics
      );
    }

    functionCallRegex.lastIndex = 0;
  });

  return diagnostics;
}
