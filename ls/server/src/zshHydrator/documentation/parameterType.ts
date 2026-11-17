type CodeParameterType = {
  readonly end: number;
  readonly literalValues: readonly string[];
};

function whitespace(text: string, start: number): number {
  let cursor = start;
  while (text[cursor] === ' ' || text[cursor] === '\t') {
    cursor += 1;
  }
  return cursor;
}

/** 引用内の内容を評価せず、コード型と文字列の選択肢を読む。 */
export function parseCodeParameterType(text: string, start: number): CodeParameterType | null {
  if (!text.startsWith('[code', start)) {
    return null;
  }
  let cursor = start + 5;
  const literalValues: string[] = [];
  while (cursor < text.length) {
    cursor = whitespace(text, cursor);
    if (text[cursor] === ']') {
      return { end: cursor + 1, literalValues };
    }
    if (text[cursor] !== '|') {
      return null;
    }
    cursor = whitespace(text, cursor + 1);
    const quote = text[cursor];
    if (quote !== "'" && quote !== '"') {
      return null;
    }
    cursor += 1;
    let value = '';
    while (cursor < text.length && text[cursor] !== quote) {
      if (text[cursor] === '\\' && (text[cursor + 1] === quote || text[cursor + 1] === '\\')) {
        cursor += 1;
      }
      value += text[cursor] ?? '';
      cursor += 1;
    }
    if (text[cursor] !== quote) {
      return null;
    }
    literalValues.push(value);
    cursor += 1;
  }
  return null;
}
