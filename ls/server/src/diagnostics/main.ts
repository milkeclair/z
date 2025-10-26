import { TextDocument } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { Diagnostics } from './type';
import { functionCallRegex, functionDefRegex } from './regex';
import { handleFirstEmptyLine, handleEmptyLine, handleFinalNewLine } from './emptyLine';
import { handleFunctionCall } from './functionCall';
import { isInsideQuoteFunctionCall } from './functionCall/matcher';
import { isCommentLine, hasIgnoreComment } from './comment';
import { ArgsText } from './argument';

function resetRegexLastIndex() {
  functionCallRegex.lastIndex = 0;
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

  handleFirstEmptyLine(lines, diagnostics);

  lines.forEach((line, lineIndex) => {
    const trimmedLine = line.trim();
    if (isCommentLine(trimmedLine)) return;
    if (hasIgnoreComment(trimmedLine)) return;
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

      if (isInsideQuoteFunctionCall(line, startChar)) continue;

      handleFunctionCall(
        functions,
        functionName,
        ArgsText(line, endChar),
        startChar,
        endChar,
        lineIndex,
        diagnostics
      );
    }

    resetRegexLastIndex();
  });

  handleFinalNewLine(text, diagnostics, lines.length);

  return diagnostics;
}
