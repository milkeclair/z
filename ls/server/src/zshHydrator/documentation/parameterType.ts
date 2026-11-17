import { List } from 'immutable';
import { again, done, loop } from '../../util/loop';
import { horizontalWhitespaceEnd } from '../../util/text';
type CodeParameterType = { readonly end: number; readonly literalValues: readonly string[] };
function quotedChoice(
  text: string,
  start: number,
): { readonly value: string; readonly end: number } | null {
  const quote = text[start];
  if (quote !== "'" && quote !== '"') {
    return null;
  }
  return loop<
    { readonly index: number; readonly value: string },
    { readonly value: string; readonly end: number } | null
  >({ index: start + 1, value: '' }, (state) => {
    if (state.index >= text.length) {
      return done(null);
    }
    const char = text[state.index];
    if (char === quote) {
      return done({ value: state.value, end: state.index + 1 });
    }
    const escaped =
      char === '\\' && (text[state.index + 1] === quote || text[state.index + 1] === '\\');
    const index = state.index + (escaped ? 1 : 0);
    return again({ index: index + 1, value: state.value + (text[index] ?? '') });
  });
}
/** 引用内の内容を評価せず、コード型と文字列の選択肢を読む。 */
export function parseCodeParameterType(text: string, start: number): CodeParameterType | null {
  if (!text.startsWith('[code', start)) {
    return null;
  }
  const initial = { index: start + 5, values: List<string>() };
  return loop<typeof initial, CodeParameterType | null>(initial, (state) => {
    if (state.index >= text.length) {
      return done(null);
    }
    const index = horizontalWhitespaceEnd(text, state.index);
    if (text[index] === ']') {
      return done({ end: index + 1, literalValues: state.values.toArray() });
    }
    if (text[index] !== '|') {
      return done(null);
    }
    const choice = quotedChoice(text, horizontalWhitespaceEnd(text, index + 1));
    return choice
      ? again({ index: choice.end, values: state.values.push(choice.value) })
      : done(null);
  });
}
