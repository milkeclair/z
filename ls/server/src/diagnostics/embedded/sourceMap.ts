import type { WordNode } from '../../zshParser/ast';
import type { SourcePosition, SourceRange } from '../../zshParser/lexer';
import type { DecodedLiteral, SourceSpan } from './literal';

export type CodeSourceMap = {
  readonly word: WordNode;
  readonly spans: readonly SourceSpan[];
  readonly lineStarts: readonly number[];
  readonly end: number;
};

/** 入れ子の位置対応を元の単語内のオフセットへ平坦化し、変換関数の再帰的な連鎖を避ける。 */
export function createCodeSourceMap(word: WordNode, literal: DecodedLiteral, parent?: CodeSourceMap): CodeSourceMap {
  if (parent) {
    const spans = literal.spans.map(span => {
      const start = word.range.start.offset + span.start;
      const end = word.range.start.offset + span.end;
      return { start: parent.spans[start]?.start ?? parent.end,
        end: parent.spans[end - 1]?.end ?? parent.end };
    });
    return { word: parent.word, lineStarts: parent.lineStarts, spans,
      end: spans.at(-1)?.end ?? parent.spans[word.range.start.offset]?.start ?? parent.end };
  }
  const lineStarts = [0];
  for (let index = 0; index < word.raw.length; index++) {
    if (word.raw[index] === '\n' || word.raw[index] === '\r' && word.raw[index + 1] !== '\n') lineStarts.push(index + 1);
  }
  return { word, lineStarts, spans: literal.spans, end: literal.spans.at(-1)?.end ?? word.raw.length };
}

/** 元の記述内のオフセットを、物理的なUTF-16の位置へ変換する。 */
function sourcePosition(source: CodeSourceMap, offset: number): SourcePosition {
  let low = 0; let high = source.lineStarts.length;
  while (low + 1 < high) {
    const middle = Math.floor((low + high) / 2);
    if (source.lineStarts[middle] <= offset) low = middle;
    else high = middle;
  }
  return { offset: source.word.range.start.offset + offset,
    line: source.word.range.start.line + low,
    character: low === 0 ? source.word.range.start.character + offset : offset - source.lineStarts[low] };
}

/** 長さ0のEOF診断も含め、復号後の範囲を元の記述位置へ変換する。 */
export function codeRange(source: CodeSourceMap, range: SourceRange): SourceRange {
  const start = source.spans[range.start.offset]?.start ?? source.end;
  const end = range.end.offset > range.start.offset ? source.spans[range.end.offset - 1]?.end ?? source.end : start;
  return { start: sourcePosition(source, start), end: sourcePosition(source, end) };
}
