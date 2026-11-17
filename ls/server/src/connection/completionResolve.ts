import type { CodeProgram } from '../embeddedCode';
import { targetRange } from '../refreshFunctions/target';
import { CompletionItem, MarkupKind } from '../vscode_type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { commentToMarkDown } from './hook';

export function zCompletionResolve(
  result: CompletionItem,
  snapshot: FunctionSnapshot,
  programs: readonly CodeProgram[] = [],
): CompletionItem {
  const data: unknown = result.data;
  if (
    typeof data !== 'object' ||
    data === null ||
    !('uri' in data) ||
    typeof data.uri !== 'string' ||
    !('name' in data) ||
    typeof data.name !== 'string' ||
    !('offset' in data) ||
    typeof data.offset !== 'number'
  ) {
    return result;
  }
  const name = data.name;
  const uri = data.uri;
  const offset = data.offset;
  const local = 'local' in data && data.local === true;
  const candidates = local
    ? [
        ...(snapshot.documents.get(uri)?.targets?.get(name) ?? []),
        ...programs.flatMap((program) => program.targets.get(name) ?? []),
      ].filter((target) => target.uri === uri)
    : snapshot.targets.get(name)?.filter((target) => target.uri === uri);
  const target =
    candidates?.find((candidate) => targetRange(candidate).start.offset === offset) ??
    (local ? undefined : candidates?.[0]);
  if (!target) {
    return result;
  }
  return {
    ...result,
    detail: target.info.file + ':' + target.info.line,
    documentation: {
      kind: MarkupKind.Markdown,
      value: commentToMarkDown(target.info.documentation, target.name, target.info.args),
    },
  };
}
