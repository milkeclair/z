import {
  CompletionItem,
  CompletionParams,
  TextDocuments,
  TextDocument,
  CompletionItemKind,
} from '../vscode_type';
import { Func } from '../getFunctions/type';
import { zFunctionCallRegex } from './regex';

function isPrivateFunction(func: Func): boolean {
  return /(^|\.)_/.test(func.name);
}

export function zCompletion({
  params,
  documents,
  functions,
  showPrivateFunctions,
}: {
  params: CompletionParams;
  documents: TextDocuments<TextDocument>;
  functions: Func[];
  showPrivateFunctions: boolean;
}): CompletionItem[] | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;

  const line = document.getText({
    start: { line: params.position.line, character: 0 },
    end: params.position,
  });

  const match = line.match(zFunctionCallRegex);
  const matchedText = match ? match[0] : '';
  const startCharacter = params.position.character - matchedText.length;

  const items: CompletionItem[] = functions
    .filter((f) => showPrivateFunctions || !isPrivateFunction(f))
    .filter((f) => f.name.startsWith(matchedText))
    .map((f) => ({
      label: f.name,
      kind: CompletionItemKind.Function,
      data: {
        file: f.file,
        line: f.line,
        args: f.args,
      },
      textEdit: {
        range: {
          start: { line: params.position.line, character: startCharacter },
          end: params.position,
        },
        newText: f.name,
      },
    }));

  return items;
}
