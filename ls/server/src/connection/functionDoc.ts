import type { Result } from '../document/type';
import type { Func, FuncArg } from '../getFunctions/type';
import { MarkupKind } from '../vscode_type';

export function argumentName(arg: FuncArg): string {
  if (arg.isNamed) {
    return arg.name;
  }

  if (arg.name === '@' || arg.name === '*') {
    return arg.name;
  }

  return arg.position.toString();
}

export function argumentToken(arg: FuncArg): string {
  if (arg.isNamed) {
    return `${arg.name}=`;
  }

  if (arg.name === '@' || arg.name === '*') {
    return '$' + arg.name;
  }

  return '$' + arg.position.toString();
}

/** コード型と許可値を、関数コメントと同じ形式で表示する。 */
export function argumentType(arg: FuncArg): string {
  if (arg.valueType !== 'code') {
    return '';
  }

  const values = (arg.literalValues ?? []).map(
    (value) => "'" + value.replaceAll('\\', '\\\\').replaceAll("'", "\\'") + "'",
  );

  return '[' + ['code', ...values].join(' | ') + ']';
}

/** 呼び出し用の引数表記へ、型アノテーションを付ける。 */
export function argumentDisplay(arg: FuncArg): string {
  const annotation = argumentType(arg);

  return argumentToken(arg) + (annotation ? ' ' + annotation : '');
}

export function argumentDescription(doc: Result | null, arg: FuncArg): string {
  if (!doc) {
    return '';
  }

  const name = argumentName(arg);
  const patterns = [`$${name}`, `$${name}:`, `$${name}?:`, name, `${name}:`, `${name}?:`];
  const parameter = doc.parameters.find((parameter) => patterns.includes(parameter.name));

  return parameter?.description ?? '';
}

export function argumentMarkdown(func: Func, arg: FuncArg, doc: Result): string {
  const description = argumentDescription(doc, arg);
  const header = `\`${func.name} ${argumentDisplay(arg)}\``;

  if (!description) {
    return header;
  }

  return `${header}\n\n${description}`;
}

export function markdownDocumentation(value: string): {
  readonly kind: 'markdown';
  readonly value: string;
} {
  return {
    kind: MarkupKind.Markdown,
    value,
  };
}
