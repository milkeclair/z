import { HoverParams } from 'vscode-languageserver';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { Result } from '../document/type';
import { nonEmptyWordRegex } from './regex';

function extractLineContent(params: HoverParams, document: TextDocument): string {
  const line = document.getText({
    start: { line: params.position.line, character: 0 },
    end: { line: params.position.line, character: Number.MAX_SAFE_INTEGER },
  });

  let startIndex = params.position.character;
  let endIndex = params.position.character;

  const isNonEmpty = (char: string) => nonEmptyWordRegex.test(char);

  while (startIndex > 0 && isNonEmpty(line[startIndex - 1])) {
    startIndex--;
  }
  while (endIndex < line.length && isNonEmpty(line[endIndex])) {
    endIndex++;
  }

  return line.substring(startIndex, endIndex);
}

function extractCommentText(lines: string[], funcLine: number): string {
  const commentLines = [];

  const funcDefinitionIndex = 1;
  const commentStartIndex = funcDefinitionIndex + 1;
  let i = funcLine - commentStartIndex;

  while (i >= 0 && lines[i].trim().startsWith('#')) {
    commentLines.unshift(lines[i]);
    i--;
  }

  const commentText = commentLines
    .map((line) => {
      if (line.trim() === '') return '';

      const hashIndex = line.indexOf('#');
      const spaceOffset = 1;
      let comment = line.substring(hashIndex + spaceOffset);
      if (comment.startsWith(' ')) comment = comment.substring(spaceOffset);

      return comment;
    })
    .join('\n');

  return commentText;
}

function commentToMarkDown(comment: Result, funcName: string): string {
  const md = ['```zsh', `${funcName}()`, '```', '---'];

  const handleDescription = (description: string) => {
    if (description) {
      md.push(description);
      md.push('');
    }
  };

  const handleParameters = (parameters: { name: string; description: string }[]) => {
    if (parameters.length > 0) {
      md.push('**Parameters:**');
      md.push('');
      parameters.forEach((param) => {
        md.push(`- \`${param.name}\`: ${param.description}`);
      });
      md.push('');
    }
  };

  const handleReturns = (reply?: string, returnValue?: string) => {
    if (reply || returnValue) {
      md.push('**Returns:**');
      md.push('');

      if (reply) md.push(`- \`REPLY\`: ${reply}`);
      if (returnValue) md.push(`- \`return\`: ${returnValue}`);

      md.push('');
    }
  };

  const handleExample = (example?: string) => {
    if (example) {
      md.push('**Example:**');
      md.push('```zsh');
      md.push(example);
      md.push('```');
    }
  };

  handleDescription(comment.description);
  handleParameters(comment.parameters);
  handleReturns(comment.reply, comment.return);
  handleExample(comment.example);

  return md.join('\n');
}

export { extractLineContent, extractCommentText, commentToMarkDown };
