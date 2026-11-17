import { targetRange } from '../refreshFunctions/target';
import type { CodeProgram } from '../embeddedCode';
import { DefinitionParams, TextDocuments, TextDocument, Location } from '../vscode_type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { cursorAt, protocolRange } from './ast/cursor';
import { targetAtName } from './ast/context';

export function zDefinition({ params, documents, snapshot, programs }: {
  params: DefinitionParams; documents: Pick<TextDocuments<TextDocument>, 'get'>; snapshot: FunctionSnapshot; programs?: readonly CodeProgram[];
}): Location | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) return null;
  const cursor = cursorAt(snapshot, document, document.offsetAt(params.position), programs);
  const match = cursor && targetAtName(snapshot, cursor);
  return match ? Location.create(match.target.uri, protocolRange(targetRange(match.target))) : null;
}
