import type { CommentNode, SimpleCommandNode, WordNode } from '../../zshParser/ast';
import type { SourcePosition } from '../../zshParser/lexer';
import type { HydrationOptions } from '../directive';
import { parseFunctionDocumentation } from '../documentation';
import type { ClassMethodAccess } from './types';

export function methodArguments(
  command: SimpleCommandNode,
): { readonly body: WordNode | null } | null {
  return command.arguments.length <= 2 ? { body: command.arguments[1] ?? null } : null;
}

/** メソッドの先行コメントにも、通常の関数と同じ文書の節を適用する。 */
export function methodReceivers(
  comments: readonly CommentNode[],
  source: string,
  options: HydrationOptions,
) {
  function startsLine({ offset, character }: SourcePosition): boolean {
    return source.slice(offset - character, offset).trim() === '';
  }

  const byLine = new Map(
    comments
      .filter((comment) => startsLine(comment.range.start))
      .map((comment) => [comment.range.start.line, comment] as const),
  );

  return (command: SimpleCommandNode, className: string): ClassMethodAccess => {
    const start = command.range.start;

    if (!startsLine(start)) {
      return 'write';
    }

    const leading = [];

    for (let line = start.line - 1; ; line--) {
      const comment = byLine.get(line);

      if (!comment) {
        break;
      }

      leading.push(comment);
    }

    if (leading.length === 0) {
      return 'write';
    }

    const range = { start: leading[leading.length - 1].range.start, end: leading[0].range.end };
    const { documentation } = parseFunctionDocumentation(
      { comments: leading.toReversed(), range },
      source,
      options,
    );
    const receiver = documentation.parameters.findLast(
      (parameter) =>
        parameter.kind === 'namedParameterDoc' &&
        parameter.name === 'self' &&
        parameter.classReference?.className === className,
    );

    return receiver?.classReference?.access === 'read' ? 'read' : 'write';
  };
}
