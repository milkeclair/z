import { decodeLiteral } from '../../embeddedCode/literal';
import { createCodeSourceMap, sourcePosition } from '../../embeddedCode/sourceMap';
import type { SimpleCommandNode, WordNode } from '../../zshParser/ast';
import { namedKey } from '../../zshParser/ast/word/literal';
import type { SourceRange } from '../../zshParser/lexer';

/** 属性名と必須のdefault引数を、元の単語の参照を保って読み取る。 */
export function attributeArguments(command: SimpleCommandNode): {
  readonly nameNode: WordNode;
  readonly defaultValue: WordNode;
} | null {
  if (command.arguments.length !== 2) return null;

  const index = command.arguments.findIndex((word) => namedKey(word) === 'default');
  if (index < 0) return null;

  const nameNode = command.arguments[1 - index];
  return namedKey(nameNode) === 'default'
    ? null
    : { nameNode, defaultValue: command.arguments[index] };
}

/** 引用と展開の構文を保ちながら、default=を除いた値の物理位置を返す。 */
export function attributeValueRange(word: WordNode): SourceRange {
  const ranges = word.parts.flatMap((part, index): readonly SourceRange[] => {
    if (part.kind !== 'stringLiteral') return [part.range];

    const segment: WordNode = { ...word, range: part.range, raw: part.value, parts: [part] };
    const decoded = decodeLiteral(segment, true);
    if (!decoded) return [];

    const spans = decoded.spans.slice(index === 0 ? 'default='.length : 0);
    if (spans.length === 0) return [];

    const source = createCodeSourceMap(segment, decoded);
    return [
      {
        start: sourcePosition(source, spans[0].start),
        end: sourcePosition(source, spans[spans.length - 1].end),
      },
    ];
  });

  return ranges.length
    ? { start: ranges[0].start, end: ranges[ranges.length - 1].end }
    : { start: word.range.end, end: word.range.end };
}
