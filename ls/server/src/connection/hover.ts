import { HoverParams, TextDocuments, TextDocument, MarkupKind } from '../vscode_type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { commentToMarkDown } from './hook';
import { HoverContent } from './type';
import { cursorAt } from './ast/cursor';
import { targetAtName } from './ast/context';
import { zArgumentHover } from './argumentHover';

export function zHover({ params, documents, snapshot }: {
  params: HoverParams; documents: Pick<TextDocuments<TextDocument>, 'get'>; snapshot: FunctionSnapshot;
}): HoverContent | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;
  const cursor = cursorAt(snapshot, document, document.offsetAt(params.position));
  if (!cursor) return null;
  const match = targetAtName(snapshot, cursor);
  if (match) return { contents: { kind: MarkupKind.Markdown,
    value: commentToMarkDown(match.target.info.documentation, match.target.name, match.target.info.args) } };
  return zArgumentHover(snapshot, cursor);
}
