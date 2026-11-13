import { MarkupKind } from '../vscode_type';
import type { Result } from '../document/type';
import type { Func, FuncArg } from '../getFunctions/type';

export function argumentName(arg: FuncArg): string {
  if (arg.isNamed) return arg.name;
  if (arg.name === "@" || arg.name === "*") return arg.name;

  return arg.position.toString();
}

export function argumentToken(arg: FuncArg): string {
  if (arg.isNamed) return `${arg.name}=`;
  if (arg.name === "@" || arg.name === "*") return "$" + arg.name;

  return "$" + arg.position.toString();
}

export function argumentDescription(doc: Result | null, arg: FuncArg): string {
  if (!doc) return "";

  const name = argumentName(arg);
  const patterns = [`$${name}`, `$${name}:`, `$${name}?:`, name, `${name}:`, `${name}?:`];
  const parameter = doc.parameters.find((p) => patterns.includes(p.name));

  return parameter?.description ?? "";
}

export function argumentMarkdown(
  func: Func,
  arg: FuncArg,
  doc: Result,
): string {
  const description = argumentDescription(doc, arg);
  const header = `\`${func.name} ${argumentToken(arg)}\``;

  if (!description) return header;

  return `${header}\n\n${description}`;
}

export function markdownDocumentation(value: string): { kind: "markdown"; value: string } {
  return {
    kind: MarkupKind.Markdown,
    value,
  };
}
