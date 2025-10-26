import { HoverParams, TextDocument } from '../vscode_type';
import { Result } from '../document/type';
import { FuncArg } from '../getFunctions/type';
import { nonEmptyWordRegex } from './regex';

const COMMENT_CHAR = '#';
const SPACE_OFFSET = 1;
const COMMENT_START_OFFSET = 2;

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
  const commentLines: string[] = [];
  let i = funcLine - COMMENT_START_OFFSET;

  while (i >= 0 && lines[i].trim().startsWith(COMMENT_CHAR)) {
    commentLines.unshift(lines[i]);
    i--;
  }

  return commentLines
    .map((line) => {
      if (line.trim() === '') return '';

      const hashIndex = line.indexOf(COMMENT_CHAR);
      let comment = line.substring(hashIndex + SPACE_OFFSET);

      if (comment.startsWith(' ')) {
        comment = comment.substring(SPACE_OFFSET);
      }

      return comment;
    })
    .join('\n');
}

function findParameterDescription(
  parameters: { name: string; description: string }[],
  argName: string
): string {
  const patterns = [
    `$${argName}`,
    `$${argName}:`,
    `$${argName}?:`,
    argName,
    `${argName}:`,
    `${argName}?:`,
  ];

  const commentParam = parameters.find((p) => patterns.includes(p.name));
  return commentParam?.description || '';
}

function formatArgument(arg: FuncArg, parameters: { name: string; description: string }[]): string {
  const optional = arg.optional ? '?' : '';
  const argName = arg.isNamed ? arg.name : arg.name === '@' ? '@' : arg.position.toString();
  const description = findParameterDescription(parameters, argName);

  return `- \`$${argName}${optional}:\` ${description}`;
}

function commentToMarkDown(comment: Result, funcName: string, args: FuncArg[] = []): string {
  const md = ['```zsh', `${funcName}()`, '```', '---'];

  const handleDescription = (description: string) => {
    if (description) {
      const mdLineBreak = '  ';
      const lines = description.split('\n').map((line) => line + mdLineBreak);

      lines.forEach((line) => md.push(line));
      md.push('');
    }
  };

  const handleParameters = (
    parameters: { name: string; description: string }[],
    funcArgs: FuncArg[]
  ) => {
    if (funcArgs.length > 0) {
      md.push('**Parameters:**');
      md.push('');
      funcArgs.forEach((arg) => {
        md.push(formatArgument(arg, parameters));
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
  handleParameters(comment.parameters, args);
  handleReturns(comment.reply, comment.return);
  handleExample(comment.example);

  return md.join('\n');
}

export { extractLineContent, extractCommentText, commentToMarkDown };
