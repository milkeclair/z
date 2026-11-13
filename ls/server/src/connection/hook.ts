import type { Result } from '../document/type';
import type { FuncArg } from '../getFunctions/type';

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
  const argName = arg.isNamed ? arg.name : (arg.name === '@' || arg.name === '*') ? arg.name : arg.position.toString();
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

export { commentToMarkDown };
