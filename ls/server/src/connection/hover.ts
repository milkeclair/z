import { HoverParams, MarkupKind } from '../vscode_type';
import { zArgumentHover } from './argumentHover';
import { targetAtName } from './ast/context';
import { cursorAt } from './ast/cursor';
import { commentToMarkDown } from './hook';
import type { LanguageFeatureRequest } from './type';
import { HoverContent } from './type';

export function zHover({
  params,
  documents,
  snapshot,
  programs,
}: LanguageFeatureRequest<HoverParams>): HoverContent | null {
  const document = documents.get(params.textDocument.uri);

  if (!document) {
    return null;
  }

  const cursor = cursorAt(snapshot, document, document.offsetAt(params.position), programs);

  if (!cursor) {
    return null;
  }

  const match = targetAtName(snapshot, cursor);

  if (match) {
    return {
      contents: {
        kind: MarkupKind.Markdown,
        value: commentToMarkDown(
          match.target.info.documentation,
          match.target.name,
          match.target.info.args,
        ),
      },
    };
  }

  return zArgumentHover(snapshot, cursor);
}
