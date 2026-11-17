import { targetRange } from '../refreshFunctions/target';
import { DefinitionParams, Location } from '../vscode_type';
import { targetAtName } from './ast/context';
import { cursorAt, protocolRange } from './ast/cursor';
import type { LanguageFeatureRequest } from './type';

export function zDefinition({
  params,
  documents,
  snapshot,
  programs,
}: LanguageFeatureRequest<DefinitionParams>): Location | null {
  const document = documents.get(params.textDocument.uri);
  if (!document) {
    return null;
  }
  const cursor = cursorAt(snapshot, document, document.offsetAt(params.position), programs);
  const match = cursor && targetAtName(snapshot, cursor);
  return match ? Location.create(match.target.uri, protocolRange(targetRange(match.target))) : null;
}
