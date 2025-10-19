import { DiagnosticSeverity, TextDocument } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { functionCallRegex, functionDefRegex } from './regex';

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
    if (functionDefRegex.test(line)) return;

    let match;
    while ((match = functionCallRegex.exec(line)) !== null) {
      const functionName = match[1];
      const startChar = match.index;
      const endChar = startChar + functionName.length;
      const funcExists = functions.some((f) => f.name === functionName);

      if (!funcExists) {
        diagnostics.push({
          severity: DiagnosticSeverity.Error,
          range: {
            start: { line: lineIndex, character: startChar },
            end: { line: lineIndex, character: endChar },
          },
          message: `${functionName} is not defined.`,
          source: 'z-ls',
        });
      }
    }

    functionCallRegex.lastIndex = 0;
  });

  return diagnostics;
}
