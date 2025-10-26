import fs from 'fs';
import path from 'path';
import { HoverParams, TextDocuments, TextDocument, MarkupKind } from '../vscode_type';
import { Document } from '../document/main';
import { Func } from '../getFunctions/type';
import { extractLineContent, extractCommentText, commentToMarkDown } from './hook';
import { HoverContent } from './type';

export function zHover({
  params,
  documents,
  functions,
  projectRoot,
}: {
  params: HoverParams;
  documents: TextDocuments<TextDocument>;
  functions: Func[];
  projectRoot: string;
}): HoverContent | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;

  const word = extractLineContent(params, document);
  const func = functions.find((f) => f.name === word);

  if (func) {
    const funcPath = path.join(projectRoot, func.file);
    const fileContent = fs.readFileSync(funcPath, 'utf-8');
    const lines = fileContent.split('\n');

    const commentText = extractCommentText(lines, func.line);
    const commentDetail = Document(commentText);

    return {
      contents: {
        kind: MarkupKind.Markdown,
        value: commentToMarkDown(commentDetail, func.name, func.args),
      },
    };
  }

  return null;
}
