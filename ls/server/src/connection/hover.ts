import { HoverParams, TextDocuments, TextDocument, MarkupKind } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { extractLineContent, commentToMarkDown } from './hook';
import { HoverContent } from './type';
import { functionDocument } from './functionDoc';
import { zArgumentHover } from './argumentHover';

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
    const commentDetail = functionDocument(projectRoot, func);
    if (!commentDetail) return null;

    return {
      contents: {
        kind: MarkupKind.Markdown,
        value: commentToMarkDown(commentDetail, func.name, func.args),
      },
    };
  }

  return zArgumentHover({ params, documents, functions, projectRoot, word });
}
