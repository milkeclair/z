import { TextDocument } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { functionCallRegex, functionDefRegex } from './regex';
import { handleFirstEmptyLine, handleEmptyLine, handleFinalNewLine } from './emptyLine';
import { handleExistingFunctionCall } from './functionCall';

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

  handleFirstEmptyLine(lines, diagnostics);

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

  handleFinalNewLine(text, diagnostics, lines.length);

  return diagnostics;
}
