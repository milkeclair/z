import type { SourceRange } from '../zshParser/lexer';
import type { CodeProgram } from './index';
import { codeRange } from './sourceMap';

type Quote = '' | "'" | '"' | 'ansi';

/** 編集位置までの引用状態を読み、外側の文字列へ挿入するときのescape方法を決める。 */
function quoteAt(raw: string, end: number): Quote {
  let quote: Quote = '';
  for (let index = 0; index < end; index++) {
    const char = raw[index];
    if (!quote && char === '$' && raw[index + 1] === "'") {
      quote = 'ansi';
      index++;
    } else if (char === '\\' && quote !== "'") {
      index++;
    } else if (quote && char === (quote === 'ansi' ? "'" : quote)) {
      quote = '';
    } else if (!quote && (char === "'" || char === '"')) {
      quote = char;
    }
  }
  return quote;
}

function singleQuoted(text: string): string {
  return "'" + text.replaceAll("'", "'\\''") + "'";
}

/** シェルへ評価させる文字を増やさず、元の引用方式に合わせて挿入する。 */
function escaped(text: string, quote: Quote): string {
  if (quote === "'") {
    return text.replaceAll("'", "'\\''");
  }
  if (quote === '"') {
    let result = '';
    for (const char of text) {
      result += '\\$"'.includes(char) || char.charCodeAt(0) === 96 ? '\\' + char : char;
    }
    return result;
  }
  if (quote === 'ansi') {
    return text
      .replaceAll('\\', '\\\\')
      .replaceAll("'", "\\'")
      .replaceAll('\n', '\\n')
      .replaceAll('\r', '\\r')
      .replaceAll('\t', '\\t');
  }
  return singleQuoted(text);
}

/** 入れ子の各引用を順番に通し、補完編集を元文書の範囲と文字列へ戻す。 */
export function codeEdit(
  program: CodeProgram,
  range: SourceRange,
  newText: string,
): {
  readonly range: SourceRange;
  readonly newText: string;
} {
  let current: CodeProgram | undefined = program;
  let edit = { range, newText };
  while (current) {
    const mapped = codeRange(current.localSource, edit.range);
    const start = mapped.start.offset - current.word.range.start.offset;
    const end = mapped.end.offset - current.word.range.start.offset;
    const before = quoteAt(current.word.raw, start);
    const after = quoteAt(current.word.raw, end);
    if (before === after) {
      edit = { range: mapped, newText: escaped(edit.newText, before) };
    } else {
      const content =
        current.prefix +
        current.content.slice(0, edit.range.start.offset) +
        edit.newText +
        current.content.slice(edit.range.end.offset);
      const replacement = singleQuoted(content);
      edit = {
        range: current.word.range,
        newText: current.literal.unterminated ? replacement.slice(0, -1) : replacement,
      };
    }
    current = current.parent;
  }
  return edit;
}
