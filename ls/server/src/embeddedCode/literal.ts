import type { WordNode } from '../zshParser/ast';
import { ansiEscape, doubleEscape } from '../zshParser/lexer/delimiter/heredoc';

export type SourceSpan = { readonly start: number; readonly end: number };
export type DecodedLiteral = {
  readonly text: string;
  readonly spans: readonly SourceSpan[];
  readonly end: number;
  readonly unterminated?: true;
};

/** UTF-16の各単位に対応する物理的な範囲を保ち、静的なシェルの引用を取り除く。 */
export function decodeLiteral(word: WordNode, allowUnterminated = false): DecodedLiteral | null {
  if (word.parts.some((part) => part.kind !== 'stringLiteral')) {
    return null;
  }
  const raw = word.raw;
  const output: string[] = [];
  const spans: SourceSpan[] = [];
  let quote = '';
  let contentEnd = 0;
  let bytes: { readonly value: number; readonly start: number; readonly end: number }[] = [];
  const emit = (text: string, start: number, end: number): void => {
    output.push(text);
    contentEnd = end;
    for (let unit = 0; unit < text.length; unit++) {
      spans.push({ start, end });
    }
  };
  const flush = (): boolean => {
    if (!bytes.length) {
      return true;
    }
    try {
      const decoder = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true });
      let start = bytes[0].start;
      for (const byte of bytes) {
        const text = decoder.decode(new Uint8Array([byte.value]), { stream: true });
        if (text) {
          emit(text, start, byte.end);
          start = byte.end;
        }
      }
      decoder.decode();
      bytes = [];
      return true;
    } catch {
      return false;
    }
  };
  for (let index = 0; index < raw.length; index++) {
    const char = raw[index];
    if (!quote && char === '$' && raw[index + 1] === "'") {
      if (!flush()) {
        return null;
      }
      quote = 'ansi';
      index += 1;
      contentEnd = index + 1;
    } else if (quote === 'ansi' && char === '\\') {
      const escaped = ansiEscape(raw, index);
      if (!escaped.valid) {
        return null;
      }
      if (escaped.byte) {
        bytes.push({ value: escaped.value.charCodeAt(0), start: index, end: escaped.end });
      } else {
        if (!flush()) {
          return null;
        }
        emit(escaped.value, index, escaped.end);
      }
      index = escaped.end - 1;
    } else if (char === '\\' && quote !== "'") {
      if (!flush()) {
        return null;
      }
      const next = raw[index + 1];
      if (next === undefined) {
        return null;
      }
      if (!quote || doubleEscape(next)) {
        if (next === '\n') {
          index += 1;
        } else if (next === '\r' && raw[index + 2] === '\n') {
          index += 2;
        } else {
          emit(next, index, index + 2);
          index += 1;
        }
      } else {
        emit(char, index, index + 1);
      }
    } else if (quote && char === (quote === 'ansi' ? "'" : quote)) {
      if (!flush()) {
        return null;
      }
      quote = '';
      contentEnd = index;
    } else if (!quote && (char === "'" || char === '"')) {
      if (!flush()) {
        return null;
      }
      quote = char;
      contentEnd = index + 1;
    } else {
      if (!flush()) {
        return null;
      }
      emit(char, index, index + 1);
    }
  }
  if ((quote && !allowUnterminated) || !flush()) {
    return null;
  }
  const text = output.join('');
  return text.includes('\0') || !text.isWellFormed()
    ? null
    : { text, spans, end: contentEnd, ...(quote ? { unterminated: true } : {}) };
}

/** 元ソースとの位置対応を保ちながら、復号済みの名前付き引数から接頭辞を取り除く。 */
export function literalValue(source: DecodedLiteral, prefix: number): DecodedLiteral {
  return { ...source, text: source.text.slice(prefix), spans: source.spans.slice(prefix) };
}
