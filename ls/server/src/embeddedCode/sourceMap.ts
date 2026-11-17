import type { WordNode } from '../zshParser/ast';
import type { SourcePosition, SourceRange } from '../zshParser/lexer';
import type { DecodedLiteral, SourceSpan } from './literal';

export type CodeSourceMap = {
  readonly word: WordNode;
  readonly spans: readonly SourceSpan[];
  readonly lineStarts: readonly number[];
  readonly start: number;
  readonly end: number;
};

/** 入れ子の位置対応を元の単語内のオフセットへ平坦化し、変換関数の再帰的な連鎖を避ける。 */
export function createCodeSourceMap(
  word: WordNode,
  literal: DecodedLiteral,
  parent?: CodeSourceMap,
): CodeSourceMap {
  if (parent) {
    const spans = literal.spans.map((span) => {
      const start = word.range.start.offset + span.start;
      const end = word.range.start.offset + span.end;
      return {
        start: parent.spans[start]?.start ?? parent.end,
        end: parent.spans[end - 1]?.end ?? parent.end,
      };
    });
    const end = parent.spans[word.range.start.offset + literal.end]?.start ?? parent.end;
    return {
      word: parent.word,
      lineStarts: parent.lineStarts,
      spans,
      start: spans[0]?.start ?? end,
      end,
    };
  }
  const lineStarts = textLineStarts(word.raw);
  return {
    word,
    lineStarts,
    spans: literal.spans,
    start: literal.spans[0]?.start ?? literal.end,
    end: literal.end,
  };
}

/** 元の記述内のオフセットを、物理的なUTF-16の位置へ変換する。 */
export function sourcePosition(source: CodeSourceMap, offset: number): SourcePosition {
  const local = textPosition(source.lineStarts, offset);
  return {
    offset: source.word.range.start.offset + offset,
    line: source.word.range.start.line + local.line,
    character:
      local.line === 0 ? source.word.range.start.character + local.character : local.character,
  };
}

/** 長さ0のEOF診断も含め、復号後の範囲を元の記述位置へ変換する。 */
export function codeRange(source: CodeSourceMap, range: SourceRange): SourceRange {
  const start = source.spans[range.start.offset]?.start ?? source.end;
  const end =
    range.end.offset > range.start.offset
      ? (source.spans[range.end.offset - 1]?.end ?? source.end)
      : start;
  return { start: sourcePosition(source, start), end: sourcePosition(source, end) };
}

/** 元文書のカーソルを内側のUTF-16位置へ戻し、escapeの途中は編集対象から外す。 */
export function codeOffset(source: CodeSourceMap, offset: number): number | null {
  const relative = offset - source.word.range.start.offset;
  if (relative < source.start || relative > source.end) {
    return null;
  }
  let low = 0;
  let high = source.spans.length;
  while (low < high) {
    const middle = Math.floor((low + high) / 2);
    if (source.spans[middle].end <= relative) {
      low = middle + 1;
    } else {
      high = middle;
    }
  }
  const span = source.spans[low];
  if (span && span.start < relative && relative < span.end) {
    return null;
  }
  return low;
}

/** 引用の接続部分を含めず、元文書で連続する断片へ分割する。 */
export function codeRanges(
  source: CodeSourceMap,
  range: SourceRange,
  maxRanges = Number.POSITIVE_INFINITY,
): readonly SourceRange[] {
  const result: { start: number; end: number }[] = [];
  if (maxRanges <= 0) {
    return [];
  }
  for (let index = range.start.offset; index < range.end.offset; index++) {
    const span = source.spans[index];
    if (!span) {
      break;
    }
    const last = result.at(-1);
    if (last && span.start <= last.end) {
      last.end = Math.max(last.end, span.end);
    } else {
      if (result.length >= maxRanges) {
        break;
      }
      result.push({ start: span.start, end: span.end });
    }
  }
  return result.map((span) => ({
    start: sourcePosition(source, span.start),
    end: sourcePosition(source, span.end),
  }));
}

/** CRLFを一つの改行として扱い、UTF-16位置の逆引き用に行頭を保存する。 */
export function textLineStarts(text: string): readonly number[] {
  const starts = [0];
  for (let index = 0; index < text.length; index++) {
    if (text[index] === '\n' || (text[index] === '\r' && text[index + 1] !== '\n')) {
      starts.push(index + 1);
    }
  }
  return starts;
}

/** キャッシュした行頭から、復号済みコードの位置を返す。 */
export function textPosition(starts: readonly number[], offset: number): SourcePosition {
  let low = 0;
  let high = starts.length;
  while (low + 1 < high) {
    const middle = Math.floor((low + high) / 2);
    if (starts[middle] <= offset) {
      low = middle;
    } else {
      high = middle;
    }
  }
  return { offset, line: low, character: offset - starts[low] };
}
