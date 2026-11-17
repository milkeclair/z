import * as Immutable from 'immutable';
import { again, done, loop } from '../util/loop';
import type { WordNode } from '../zshParser/ast';
import { ansiEscape, doubleEscape } from '../zshParser/lexer/delimiter/heredoc';

export type SourceSpan = {
  readonly start: number;
  readonly end: number;
};

export type DecodedLiteral = {
  readonly text: string;
  readonly spans: readonly SourceSpan[];
  readonly end: number;
  readonly unterminated?: true;
};

type EncodedByte = {
  readonly value: number;
  readonly start: number;
  readonly end: number;
};

type DecodeProgress = {
  readonly index: number;
  readonly quote: string;
  readonly text: string;
  readonly contentEnd: number;
  readonly spans: Immutable.List<SourceSpan>;
  readonly bytes: Immutable.List<EncodedByte>;
};

function emit(state: DecodeProgress, text: string, start: number, end: number): DecodeProgress {
  return {
    ...state,
    text: state.text + text,
    contentEnd: end,
    spans: state.spans.concat(Immutable.Range(0, text.length).map(() => ({ start, end }))),
  };
}

function flushBytes(state: DecodeProgress): DecodeProgress | null {
  if (state.bytes.isEmpty()) {
    return state;
  }

  try {
    const bytes = state.bytes.toArray();
    const text = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true }).decode(
      Uint8Array.from(bytes.map((byte) => byte.value)),
    );
    const decoded = [...text].reduce(
      (progress, char) => {
        const length = Buffer.byteLength(char, 'utf8');
        const first = bytes[progress.offset];
        const last = bytes[progress.offset + length - 1];

        return {
          offset: progress.offset + length,
          state: emit(progress.state, char, first.start, last.end),
        };
      },
      { offset: 0, state },
    );

    return { ...decoded.state, bytes: Immutable.List() };
  } catch {
    return null;
  }
}

function finishLiteral(state: DecodeProgress, allowUnterminated: boolean): DecodedLiteral | null {
  if (state.quote && !allowUnterminated) {
    return null;
  }

  const flushed = flushBytes(state);

  if (!flushed || flushed.text.includes('\0') || !flushed.text.isWellFormed()) {
    return null;
  }

  return {
    text: flushed.text,
    spans: flushed.spans.toArray(),
    end: flushed.contentEnd,
    ...(state.quote ? { unterminated: true } : {}),
  };
}

function readAnsiLiteralEscape(raw: string, state: DecodeProgress): DecodeProgress | null {
  const { index } = state;
  const escaped = ansiEscape(raw, index);

  if (!escaped.valid) {
    return null;
  }

  if (escaped.byte) {
    return {
      ...state,
      index: escaped.end,
      bytes: state.bytes.push({
        value: escaped.value.charCodeAt(0),
        start: index,
        end: escaped.end,
      }),
    };
  }

  const current = flushBytes(state);

  return current
    ? { ...emit(current, escaped.value, index, escaped.end), index: escaped.end }
    : null;
}

function readLiteralBackslash(raw: string, current: DecodeProgress): DecodeProgress | null {
  const { index, quote } = current;
  const char = raw[index];
  const next = raw[index + 1];

  if (next === undefined) {
    return null;
  }

  if (!quote || doubleEscape(next)) {
    if (next === '\n') {
      return { ...current, index: index + 2 };
    }

    if (next === '\r' && raw[index + 2] === '\n') {
      return { ...current, index: index + 3 };
    }

    return { ...emit(current, next, index, index + 2), index: index + 2 };
  }

  return { ...emit(current, char, index, index + 1), index: index + 1 };
}

function readLiteralCharacter(raw: string, state: DecodeProgress): DecodeProgress | null {
  const { index, quote } = state;
  const char = raw[index];

  if (!quote && char === '$' && raw[index + 1] === "'") {
    const current = flushBytes(state);

    return current ? { ...current, index: index + 2, quote: 'ansi', contentEnd: index + 2 } : null;
  }

  if (quote === 'ansi' && char === '\\') return readAnsiLiteralEscape(raw, state);

  const current = flushBytes(state);

  if (!current) {
    return null;
  }

  if (char === '\\' && quote !== "'") return readLiteralBackslash(raw, current);

  if (quote && char === (quote === 'ansi' ? "'" : quote)) {
    return { ...current, index: index + 1, quote: '', contentEnd: index };
  }

  if (!quote && (char === "'" || char === '"')) {
    return { ...current, index: index + 1, quote: char, contentEnd: index + 1 };
  }

  return { ...emit(current, char, index, index + 1), index: index + 1 };
}

/** UTF-16の各単位に対応する物理的な範囲を保ち、静的なシェルの引用を取り除く。 */
export function decodeLiteral(word: WordNode, allowUnterminated = false): DecodedLiteral | null {
  if (word.parts.some((part) => part.kind !== 'stringLiteral')) {
    return null;
  }

  const raw = word.raw;
  const initial: DecodeProgress = {
    index: 0,
    quote: '',
    text: '',
    contentEnd: 0,
    spans: Immutable.List(),
    bytes: Immutable.List(),
  };

  return loop<DecodeProgress, DecodedLiteral | null>(initial, (state) => {
    if (state.index >= raw.length) return done(finishLiteral(state, allowUnterminated));

    const next = readLiteralCharacter(raw, state);

    return next ? again(next) : done(null);
  });
}

/** 元ソースとの位置対応を保ちながら、復号済みの名前付き引数から接頭辞を取り除く。 */
export function literalValue(source: DecodedLiteral, prefix: number): DecodedLiteral {
  return { ...source, text: source.text.slice(prefix), spans: source.spans.slice(prefix) };
}
