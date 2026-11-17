import type { Result } from '../document/type';
import type { FuncArg } from '../getFunctions/type';
import { argumentType } from './functionDoc';

function findParameterDescription(
  parameters: readonly {
    readonly name: string;
    readonly description: string;
  }[],
  argName: string,
): string {
  const patterns = [
    `$${argName}`,
    `$${argName}:`,
    `$${argName}?:`,
    argName,
    `${argName}:`,
    `${argName}?:`,
  ];

  const commentParam = parameters.find((parameter) => patterns.includes(parameter.name));

  return commentParam?.description || '';
}

function formatArgument(
  arg: FuncArg,
  parameters: readonly {
    readonly name: string;
    readonly description: string;
  }[],
): string {
  const optional = arg.optional ? '?' : '';
  const type = argumentType(arg);
  const annotation = type ? ' ' + type : '';
  const argName = arg.isNamed
    ? arg.name
    : arg.name === '@' || arg.name === '*'
      ? arg.name
      : arg.position.toString();
  const description = findParameterDescription(parameters, argName);

  return `- \`$${argName}${optional}${annotation}:\` ${description}`;
}

function commentToMarkDown(
  comment: Result,
  funcName: string,
  args: readonly FuncArg[] = [],
): string {
  const description = comment.description
    ? [...comment.description.split('\n').map((line) => line + '  '), '']
    : [];
  const parameters = args.length
    ? [
        '**Parameters:**',
        '',
        ...args.map((argument) => formatArgument(argument, comment.parameters)),
        '',
      ]
    : [];
  const returns =
    comment.reply || comment.return
      ? [
          '**Returns:**',
          '',
          ...(comment.reply ? [`- \`REPLY\`: ${comment.reply}`] : []),
          ...(comment.return ? [`- \`return\`: ${comment.return}`] : []),
          '',
        ]
      : [];
  const example = comment.example ? ['**Example:**', '```zsh', comment.example, '```'] : [];

  return [
    '```zsh',
    `${funcName}()`,
    '```',
    '---',
    ...description,
    ...parameters,
    ...returns,
    ...example,
  ].join('\n');
}

export { commentToMarkDown };
