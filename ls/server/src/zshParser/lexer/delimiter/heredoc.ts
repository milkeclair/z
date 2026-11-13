type Escape = { readonly value: string; readonly end: number; readonly byte: boolean };

export function doubleEscape(char: string): boolean {
  return '$"\\\n'.includes(char) || char.charCodeAt(0) === 96;
}

/** Decode one ANSI quoted escape without evaluating shell expansions. */
function ansiEscape(raw: string, start: number): Escape {
  let index = start + 1;
  let mask = 0;
  let control = false;
  while ((raw[index] === 'M' || raw[index] === 'C') && raw[index + 1] === '-') {
    if (raw[index] === 'M') mask = 128;
    else control = true;
    index += 2;
    if (raw[index] === '\\') index += 1;
  }
  const char = raw[index] ?? '';
  const named: Readonly<Record<string, string>> = {
    a: '\x07', b: '\b', e: '\x1b', E: '\x1b', f: '\f',
    n: '\n', r: '\r', t: '\t', v: '\x0b',
  };
  let value = named[char] ?? char;
  let end = index + 1;
  let byte = false;
  const octal = char >= '0' && char <= '7';
  if (octal || char === 'x' || char === 'u' || char === 'U') {
    const digits = octal ? '01234567' : '0123456789abcdef';
    const first = octal ? index : index + 1;
    const limit = octal ? 3 : char === 'x' ? 2 : char === 'u' ? 4 : 8;
    end = first;
    while (end < raw.length && end < first + limit && digits.includes(raw[end].toLowerCase())) end += 1;
    if (end > first) {
      const code = Number.parseInt(raw.slice(first, end), octal ? 8 : 16);
      byte = octal || char === 'x';
      value = String.fromCodePoint(byte ? code & 255 : Math.min(code, 0x10ffff));
    } else end = index + 1;
  }
  if (mask || control) {
    const code = value.charCodeAt(0);
    value = String.fromCharCode((control ? code === 63 ? 127 : code & 31 : code) | mask);
    byte = true;
  }
  return { value, end, byte };
}

/** Remove quoting from a here-document delimiter while preserving literal expansions. */
export function removeHereDocQuotes(raw: string, stripTabs: boolean, commandEnd: (start: number) => number | null): { readonly delimiter: string; readonly quoted: boolean } {
  let quote = '';
  let delimiter = '';
  let quoted = false;
  let bytes: number[] = [];
  const flush = (): void => {
    if (bytes.length) delimiter += new TextDecoder('utf-8', { ignoreBOM: true }).decode(new Uint8Array(bytes));
    bytes = [];
  };
  for (let index = 0; index < raw.length; index += 1) {
    const char = raw[index];
    if (quote !== "'" && quote !== 'ansi' && char === '$' && raw[index + 1] === '(') {
      const end = commandEnd(index);
      if (end !== null) { flush(); delimiter += raw.slice(index, end); index = end - 1; continue; }
    }
    if (!quote && char === '$' && raw[index + 1] === "'") {
      flush(); quote = 'ansi'; quoted = true; index += 1;
    } else if (quote === 'ansi' && char === '\\') {
      const escaped = ansiEscape(raw, index);
      if (escaped.byte) bytes.push(escaped.value.charCodeAt(0));
      else { flush(); delimiter += escaped.value; }
      index = escaped.end - 1;
    } else if (char === '\\' && quote !== "'") {
      flush();
      const next = raw[index + 1] ?? '';
      if (!quote || doubleEscape(next)) {
        if (next !== '\n' && !(next === '\r' && raw[index + 2] === '\n')) {
          delimiter += next;
          quoted = true;
        }
        index += next === '\r' && raw[index + 2] === '\n' ? 2 : 1;
      } else { delimiter += char; quoted = true; }
    } else if (quote && char === (quote === 'ansi' ? "'" : quote)) {
      flush();
      if (quote.charCodeAt(0) === 96) delimiter += char;
      quote = ''; quoted = true;
    } else if (!quote && (char === "'" || char === '"' || char.charCodeAt(0) === 96)) {
      flush(); quote = char; quoted = true;
      if (char.charCodeAt(0) === 96) delimiter += char;
    } else {
      flush(); delimiter += char;
    }
  }
  flush();
  if (stripTabs) {
    let first = 0;
    while (delimiter[first] === '\t') first += 1;
    delimiter = delimiter.slice(first);
  }
  return { delimiter, quoted };
}

/** Locate the physical span of a logical delimiter line, preserving all source text. */
export function hereDocEnd(
  text: string, start: number,
  request: { readonly delimiter: string; readonly quoted: boolean; readonly stripTabs: boolean },
): { readonly start: number; readonly end: number } | null {
  let index = start;
  while (index < text.length) {
    const lineStart = index;
    let line = '';
    let physicalStart = true;
    while (index < text.length) {
      const char = text[index];
      if (physicalStart && request.stripTabs && char === '\t') { index += 1; continue; }
      physicalStart = false;
      if (!request.quoted && char === '\\') {
        const next = text[index + 1];
        if (next === '\n' || next === '\r' && text[index + 2] === '\n') {
          index += next === '\n' ? 2 : 3;
          continue;
        }
        if (next === '\\') { line += '\\\\'; index += 2; continue; }
      }
      if (char === '\r' || char === '\n') break;
      line += char;
      index += 1;
    }
    if (text[index] === '\r' && text[index + 1] === '\n') index += 2;
    else if (index < text.length) index += 1;
    if (line === request.delimiter) return { start: lineStart, end: index };
  }
  return null;
}
