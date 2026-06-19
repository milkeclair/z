import fs from 'fs';
import path from 'path';
import { CompletionItem, MarkupKind } from '../vscode_type';
import { Document } from '../document/main';
import { FuncArg } from '../getFunctions/type';
import { extractCommentText, commentToMarkDown } from './hook';

type CompletionData = {
  file: string;
  line: number;
  args: FuncArg[];
};

type UnknownRecord = Record<string, unknown>;

function isRecord(value: unknown): value is UnknownRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isFuncArg(value: unknown): value is FuncArg {
  if (!isRecord(value)) return false;

  return (
    typeof value.position === 'number' &&
    typeof value.name === 'string' &&
    typeof value.optional === 'boolean' &&
    typeof value.isNamed === 'boolean'
  );
}

function completionData(value: unknown): CompletionData | null {
  if (!isRecord(value)) return null;
  if (typeof value.file !== 'string') return null;
  if (typeof value.line !== 'number') return null;
  if (!Array.isArray(value.args)) return null;
  if (!value.args.every(isFuncArg)) return null;

  return {
    file: value.file,
    line: value.line,
    args: value.args,
  };
}

export function zCompletionResolve(result: CompletionItem, projectRoot: string): CompletionItem {
  const data = completionData(result.data);
  if (!data) return result;

  const details = data.file + ':' + data.line;
  result.detail = details;

  const funcPath = path.join(projectRoot, data.file);
  if (!fs.existsSync(funcPath)) return result;

  const fileContent = fs.readFileSync(funcPath, 'utf-8');
  const lines = fileContent.split('\n');
  const commentText = extractCommentText(lines, data.line);
  const commentDetail = Document(commentText);

  result.documentation = {
    kind: MarkupKind.Markdown,
    value: commentToMarkDown(commentDetail, result.label, data.args),
  };

  return result;
}
