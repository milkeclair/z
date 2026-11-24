import type { CommentNode, SimpleCommandNode, WordNode } from '../../zshParser/ast';
import { parseParameter } from '../documentation/parameter';
import type { ClassMethodAccess } from './types';

/** メソッド本体の単語を元の範囲のまま取得する。 */
export function methodArguments(
  command: SimpleCommandNode,
): { readonly body: WordNode | null } | null {
  return command.arguments.length <= 2 ? { body: command.arguments[1] ?? null } : null;
}

/** 直前に連続する独立したコメントから、受け手の契約を読む。 */
export function methodReceivers(comments: readonly CommentNode[], source: string) {
  function startsLine(offset: number) {
    const start = source.lastIndexOf('\n', offset - 1) + 1;
    return source.slice(start, offset).trim() === '';
  }

  const byLine = new Map(
    comments
      .filter((comment) => startsLine(comment.range.start.offset))
      .map((comment) => [comment.range.end.line, comment] as const),
  );

  return (command: SimpleCommandNode, className: string): ClassMethodAccess => {
    if (!startsLine(command.range.start.offset)) return 'write';

    for (let line = command.range.start.line - 1; byLine.has(line); line--) {
      const comment = byLine.get(line);
      if (!comment) break;
      const parameter = parseParameter(comment);
      if (
        parameter?.kind === 'namedParameterDoc' &&
        parameter.name === 'self' &&
        parameter.classReference?.className === className
      ) {
        return parameter.classReference.access === 'read' ? 'read' : 'write';
      }
    }

    return 'write';
  };
}
