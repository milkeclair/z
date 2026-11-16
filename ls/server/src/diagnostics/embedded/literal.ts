import type { WordNode } from '../../zshParser/ast';
import { ansiEscape, doubleEscape } from '../../zshParser/lexer/delimiter/heredoc';

export type SourceSpan = { readonly start: number; readonly end: number };
export type DecodedLiteral = { readonly text: string; readonly spans: readonly SourceSpan[] };

/** Remove static shell quoting while retaining the physical span of each UTF-16 unit. */
export function decodeLiteral(word: WordNode): DecodedLiteral | null {
  if (word.parts.some(part => part.kind !== 'stringLiteral')) return null;
  const raw = word.raw;
  const output: string[] = [];
  const spans: SourceSpan[] = [];
  let quote = '';
  let bytes: { readonly value: number; readonly start: number; readonly end: number }[] = [];
  const emit = (text: string, start: number, end: number): void => {
    output.push(text);
    for (let unit = 0; unit < text.length; unit++) spans.push({ start, end });
  };
  const flush = (): boolean => {
    if (!bytes.length) return true;
    try {
      const decoder = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
      let start = bytes[0].start;
      for (const byte of bytes) {
        const text = decoder.decode(new Uint8Array([byte.value]), { stream: true });
        if (text) { emit(text, start, byte.end); start = byte.end; }
      }
      decoder.decode();
      bytes = [];
      return true;
    } catch { return false; }
  };
  for (let index = 0; index < raw.length; index++) {
    const char = raw[index];
    if (!quote && char === '$' && raw[index + 1] === "'") {
      if (!flush()) return null;
      quote = 'ansi'; index += 1;
    } else if (quote === 'ansi' && char === '\\') {
      const escaped = ansiEscape(raw, index);
      if (!escaped.valid) return null;
      if (escaped.byte) bytes.push({ value: escaped.value.charCodeAt(0), start: index, end: escaped.end });
      else {
        if (!flush()) return null;
        emit(escaped.value, index, escaped.end);
      }
      index = escaped.end - 1;
    } else if (char === '\\' && quote !== "'") {
      if (!flush()) return null;
      const next = raw[index + 1];
      if (next === undefined) return null;
      if (!quote || doubleEscape(next)) {
        if (next === '\n') index += 1;
        else if (next === '\r' && raw[index + 2] === '\n') index += 2;
        else { emit(next, index, index + 2); index += 1; }
      } else emit(char, index, index + 1);
    } else if (quote && char === (quote === 'ansi' ? "'" : quote)) {
      if (!flush()) return null;
      quote = '';
    } else if (!quote && (char === "'" || char === '"')) {
      if (!flush()) return null;
      quote = char;
    } else {
      if (!flush()) return null;
      emit(char, index, index + 1);
    }
  }
  if (quote || !flush()) return null;
  const text = output.join('');
  return text.includes('\0') || !text.isWellFormed() ? null : { text, spans };
}

/** Drop a decoded named-argument prefix without discarding its source-coordinate mapping. */
export function literalValue(source: DecodedLiteral, prefix: number): DecodedLiteral {
  return { text: source.text.slice(prefix), spans: source.spans.slice(prefix) };
}
