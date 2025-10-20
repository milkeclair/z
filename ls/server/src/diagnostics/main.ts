import { DiagnosticSeverity, TextDocument } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { functionCallRegex, functionDefRegex } from './regex';
import { findClosestMatch } from '../util/levenshtein';

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

    let match;
    while ((match = functionCallRegex.exec(line)) !== null) {
      const functionName = match[1];
      const startChar = match.index;
      const endChar = startChar + functionName.length;
      const funcExists = functions.some((f) => f.name === functionName);

      if (!funcExists) {
        const functionNames = functions.map((f) => f.name);
        const suggestion = findClosestMatch(functionName, functionNames);

        const message = suggestion
          ? `${functionName} is not defined. Did you mean '${suggestion}'?`
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

    functionCallRegex.lastIndex = 0;
  });

  return diagnostics;
}
