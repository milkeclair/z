import path from 'path';
import { DefinitionParams, TextDocuments, TextDocument, Location } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { extractLineContent } from './hook';

export function zDefinition({
  params,
  documents,
  functions,
  projectRoot,
}: {
  params: DefinitionParams;
  documents: TextDocuments<TextDocument>;
  functions: Func[];
  projectRoot: string;
}): Location | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;

  const word = extractLineContent(params, document);
  const func = functions.find((f) => f.name === word);

  if (func) {
    const funcPath = path.join(projectRoot, func.file);
    const funcUri = 'file://' + funcPath;
    const indexOffset = 1;
    const range = {
      start: { line: func.line - indexOffset, character: 0 },
      end: { line: func.line - indexOffset, character: func.name.length },
    };
    return Location.create(funcUri, range);
  }

  return null;
}
