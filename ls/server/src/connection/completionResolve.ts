import { CompletionItem, MarkupKind } from '../vscode_type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { commentToMarkDown } from './hook';

export function zCompletionResolve(result: CompletionItem, snapshot: FunctionSnapshot): CompletionItem {
  const data: unknown = result.data;
  if (typeof data !== 'object' || data === null ||
    !('uri' in data) || typeof data.uri !== 'string' ||
    !('name' in data) || typeof data.name !== 'string' ||
    !('offset' in data) || typeof data.offset !== 'number') return result;
  const candidates = snapshot.targets.get(data.name)?.filter(target => target.uri === data.uri);
  const target = candidates?.find(candidate => candidate.nameNode.range.start.offset === data.offset) ?? candidates?.[0];
  if (!target) return result;
  return { ...result, detail: target.info.file + ':' + target.info.line,
    documentation: { kind: MarkupKind.Markdown,
      value: commentToMarkDown(target.info.documentation, target.name, target.info.args) } };
}
