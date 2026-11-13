import { MarkupKind } from '../vscode_type';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import type { Cursor } from './ast/cursor';
import { argumentAt, calledFunction, activeArgument, ownerFunction } from './ast/context';
import { parameterArgument } from './ast/parameter';
import { argumentMarkdown } from './functionDoc';

export function zArgumentHover(snapshot: FunctionSnapshot, cursor: Cursor) {
  const target = calledFunction(snapshot, cursor);
  const active = target && argumentAt(cursor) && activeArgument(target, cursor);
  if (target && active) return { contents: { kind: MarkupKind.Markdown,
    value: argumentMarkdown(target.info, active.argument, target.info.documentation) } };
  const owner = ownerFunction(snapshot, cursor);
  const argument = owner && parameterArgument(owner, cursor);
  return owner && argument ? { contents: { kind: MarkupKind.Markdown,
    value: argumentMarkdown(owner.info, argument, owner.info.documentation) } } : null;
}
