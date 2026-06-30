import fs from "fs";
import path from "path";
import { MarkupKind } from "../vscode_type";
import { Result } from "../document/type";
import { Document } from "../document/main";
import { Func, FuncArg } from "../getFunctions/type";
import { extractCommentText } from "./hook";

export function functionDocument(projectRoot: string, func: Func): Result | null {
  const funcPath = path.join(projectRoot, func.file);
  if (!fs.existsSync(funcPath)) return null;

  const fileContent = fs.readFileSync(funcPath, "utf-8");
  const lines = fileContent.split("\n");
  const commentText = extractCommentText(lines, func.line);

  return Document(commentText);
}

export function argumentName(arg: FuncArg): string {
  if (arg.isNamed) return arg.name;
  if (arg.name === "@") return "@";

  return arg.position.toString();
}

export function argumentToken(arg: FuncArg): string {
  if (arg.isNamed) return `${arg.name}=`;
  if (arg.name === "@") return "$@";

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
  projectRoot: string,
  func: Func,
  arg: FuncArg,
  doc?: Result | null,
): string {
  const resolvedDoc = doc === undefined ? functionDocument(projectRoot, func) : doc;
  const description = argumentDescription(resolvedDoc, arg);
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
