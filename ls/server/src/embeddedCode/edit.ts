import { again, done, loop } from '../util/loop';
import type { SourceRange } from '../zshParser/lexer';
import type { CodeProgram } from './index';
import { codeRange } from './sourceMap';

type Quote = '' | "'" | '"' | 'ansi';

/** 編集位置までの引用状態を読み、外側の文字列へ挿入するときのescape方法を決める。 */
function quoteAt(raw: string, end: number): Quote {
  return loop<{ readonly index: number; readonly quote: Quote }, Quote>(
    { index: 0, quote: '' },
    (state) => {
      const { index, quote } = state;
      if (index >= end) {
        return done(quote);
      }
      const char = raw[index];
      if (!quote && char === '$' && raw[index + 1] === "'") {
        return again({ index: index + 2, quote: 'ansi' });
      }
      if (char === '\\' && quote !== "'") {
        return again({ index: index + 2, quote });
      }
      const closed = quote && char === (quote === 'ansi' ? "'" : quote);
      const opened = !quote && (char === "'" || char === '"');
      return again({ index: index + 1, quote: closed ? '' : opened ? char : quote });
    },
  );
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
    return [...text]
      .map((char) => ('\\$"'.includes(char) || char.charCodeAt(0) === 96 ? '\\' + char : char))
      .join('');
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
  type Edit = { readonly range: SourceRange; readonly newText: string };
  type Progress = { readonly current: CodeProgram | undefined; readonly edit: Edit };
  return loop<Progress, Edit>({ current: program, edit: { range, newText } }, (state) => {
    const { current, edit } = state;
    if (!current) {
      return done(edit);
    }
    const mapped = codeRange(current.localSource, edit.range);
    const start = mapped.start.offset - current.word.range.start.offset;
    const end = mapped.end.offset - current.word.range.start.offset;
    const before = quoteAt(current.word.raw, start),
      after = quoteAt(current.word.raw, end);
    if (before === after) {
      return again({
        current: current.parent,
        edit: { range: mapped, newText: escaped(edit.newText, before) },
      });
    }
    const content =
      current.prefix +
      current.content.slice(0, edit.range.start.offset) +
      edit.newText +
      current.content.slice(edit.range.end.offset);
    const replacement = singleQuoted(content);
    return again({
      current: current.parent,
      edit: {
        range: current.word.range,
        newText: current.literal.unterminated ? replacement.slice(0, -1) : replacement,
      },
    });
  });
}
