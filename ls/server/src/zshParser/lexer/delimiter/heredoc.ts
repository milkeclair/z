import { List, Range } from 'immutable';
import { loop, again, done } from '../../../util/loop';

export type Escape = {
  readonly value: string;
  readonly end: number;
  readonly byte: boolean;
  readonly valid: boolean;
};
type EscapePrefix = {
  readonly index: number;
  readonly mask: number;
  readonly control: boolean;
  readonly escapedCharacter: boolean;
};
const NAMED_ESCAPES: Readonly<Record<string, string>> = {
  a: '\x07',
  b: '\b',
  e: '\x1b',
  E: '\x1b',
  f: '\f',
  n: '\n',
  r: '\r',
  t: '\t',
  v: '\x0b',
};
export function doubleEscape(char: string): boolean {
  return '$"\\\n'.includes(char) || char.charCodeAt(0) === 96;
}

function escapePrefix(raw: string, start: number): EscapePrefix {
  return loop<EscapePrefix, EscapePrefix>(
    { index: start + 1, mask: 0, control: false, escapedCharacter: true },
    (state) => {
      const kind = raw[state.index];
      if ((kind !== 'M' && kind !== 'C') || raw[state.index + 1] !== '-') {
        return done(state);
      }
      const next = state.index + 2,
        escapedCharacter = raw[next] === '\\';
      return again({
        index: next + (escapedCharacter ? 1 : 0),
        mask: kind === 'M' ? 128 : state.mask,
        control: state.control || kind === 'C',
        escapedCharacter,
      });
    },
  );
}
function escapeValue(raw: string, prefix: EscapePrefix): Escape {
  const { index, escapedCharacter } = prefix;
  const char = raw[index] ?? '';
  const octal = char >= '0' && char <= '7';
  if (escapedCharacter && (octal || char === 'x' || char === 'u' || char === 'U')) {
    const digits = octal ? '01234567' : '0123456789abcdef';
    const first = octal ? index : index + 1;
    const limit = octal ? 3 : char === 'x' ? 2 : char === 'u' ? 4 : 8;
    const boundary = Math.min(raw.length, first + limit);
    const end =
      Range(first, boundary).find((cursor) => !digits.includes(raw[cursor].toLowerCase())) ??
      boundary;
    if (end > first) {
      const code = Number.parseInt(raw.slice(first, end), octal ? 8 : 16);
      const byte = octal || char === 'x';
      return {
        end,
        byte,
        valid: byte || (code <= 0x10ffff && (code < 0xd800 || code > 0xdfff)),
        value: String.fromCodePoint(byte ? code & 255 : Math.min(code, 0x10ffff)),
      };
    }
    return { value: '\0', byte: true, valid: true, end: index + 1 };
  }
  return {
    value: escapedCharacter ? (NAMED_ESCAPES[char] ?? char) : char,
    end: index + 1,
    byte: false,
    valid: true,
  };
}
/** シェル展開を評価せず、ANSI引用内のエスケープを1つ復号する。 */
export function ansiEscape(raw: string, start: number): Escape {
  const prefix = escapePrefix(raw, start),
    decoded = escapeValue(raw, prefix);
  if (!prefix.mask && !prefix.control) {
    return decoded;
  }
  const code = decoded.value.charCodeAt(0);
  return {
    ...decoded,
    value: String.fromCharCode(
      (prefix.control ? (code === 63 ? 127 : code & 31) : code) | prefix.mask,
    ),
    byte: true,
  };
}

type DelimiterProgress = {
  readonly index: number;
  readonly quote: string;
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly bytes: List<number>;
};
function flushDelimiter(state: DelimiterProgress): DelimiterProgress {
  if (state.bytes.isEmpty()) {
    return state;
  }
  const text = new TextDecoder('utf-8', { ignoreBOM: true }).decode(Uint8Array.from(state.bytes));
  return { ...state, delimiter: state.delimiter + text, bytes: List() };
}
/** 展開を文字列のまま保ち、ヒアドキュメントの終端名から引用を取り除く。 */
export function removeHereDocQuotes(
  raw: string,
  stripTabs: boolean,
  commandEnd: (start: number) => number | null,
): {
  readonly delimiter: string;
  readonly quoted: boolean;
} {
  const initial: DelimiterProgress = {
    index: 0,
    quote: '',
    delimiter: '',
    quoted: false,
    bytes: List(),
  };
  const parsed = loop<DelimiterProgress, DelimiterProgress>(initial, (state) => {
    const { index, quote } = state;
    if (index >= raw.length) {
      return done(flushDelimiter(state));
    }
    const char = raw[index];
    if (quote !== "'" && quote !== 'ansi' && char === '$' && raw[index + 1] === '(') {
      const end = commandEnd(index);
      if (end !== null) {
        const current = flushDelimiter(state);
        return again({
          ...current,
          index: end,
          delimiter: current.delimiter + raw.slice(index, end),
        });
      }
    }
    if (!quote && char === '$' && raw[index + 1] === "'") {
      return again({ ...flushDelimiter(state), index: index + 2, quote: 'ansi', quoted: true });
    }
    if (quote === 'ansi' && char === '\\') {
      const escaped = ansiEscape(raw, index);
      if (escaped.byte) {
        return again({
          ...state,
          index: escaped.end,
          bytes: state.bytes.push(escaped.value.charCodeAt(0)),
        });
      }
      const current = flushDelimiter(state);
      return again({
        ...current,
        index: escaped.end,
        delimiter: current.delimiter + escaped.value,
      });
    }
    const current = flushDelimiter(state);
    if (char === '\\' && quote !== "'") {
      const next = raw[index + 1] ?? '';
      if (!quote || doubleEscape(next)) {
        const continuation = next === '\n' || (next === '\r' && raw[index + 2] === '\n');
        return again({
          ...current,
          index: index + (next === '\r' && raw[index + 2] === '\n' ? 3 : 2),
          delimiter: current.delimiter + (continuation ? '' : next),
          quoted: continuation ? current.quoted : true,
        });
      }
      return again({
        ...current,
        index: index + 1,
        delimiter: current.delimiter + char,
        quoted: true,
      });
    }
    if (quote && char === (quote === 'ansi' ? "'" : quote)) {
      return again({
        ...current,
        index: index + 1,
        quote: '',
        quoted: true,
        delimiter: current.delimiter + (quote.charCodeAt(0) === 96 ? char : ''),
      });
    }
    if (!quote && (char === "'" || char === '"' || char.charCodeAt(0) === 96)) {
      return again({
        ...current,
        index: index + 1,
        quote: char,
        quoted: true,
        delimiter: current.delimiter + (char.charCodeAt(0) === 96 ? char : ''),
      });
    }
    return again({ ...current, index: index + 1, delimiter: current.delimiter + char });
  });
  return {
    delimiter: stripTabs ? parsed.delimiter.replace(/^\t+/, '') : parsed.delimiter,
    quoted: parsed.quoted,
  };
}

type HereDocRequest = {
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly stripTabs: boolean;
};
type LogicalLine = {
  readonly index: number;
  readonly line: string;
  readonly physicalStart: boolean;
};
function logicalLine(text: string, start: number, request: HereDocRequest): LogicalLine {
  return loop<LogicalLine, LogicalLine>(
    { index: start, line: '', physicalStart: true },
    (state) => {
      const { index, line } = state;
      if (index >= text.length) {
        return done(state);
      }
      const char = text[index];
      if (state.physicalStart && request.stripTabs && char === '\t') {
        return again({ ...state, index: index + 1 });
      }
      const current = { ...state, physicalStart: false };
      if (!request.quoted && char === '\\') {
        const next = text[index + 1];
        if (next === '\n' || (next === '\r' && text[index + 2] === '\n')) {
          return again({ ...current, index: index + (next === '\n' ? 2 : 3) });
        }
        if (next === '\\') {
          return again({ ...current, index: index + 2, line: line + '\\\\' });
        }
      }
      return char === '\r' || char === '\n'
        ? done(current)
        : again({ ...current, index: index + 1, line: line + char });
    },
  );
}
/** ソース全文を保ちながら、論理的な終端行に対応する物理的な範囲を見つける。 */
export function hereDocEnd(
  text: string,
  start: number,
  request: HereDocRequest,
): { readonly start: number; readonly end: number } | null {
  return loop<number, { readonly start: number; readonly end: number } | null>(start, (index) => {
    if (index >= text.length) {
      return done(null);
    }
    const line = logicalLine(text, index, request);
    const next =
      text[line.index] === '\r' && text[line.index + 1] === '\n'
        ? line.index + 2
        : line.index < text.length
          ? line.index + 1
          : line.index;
    return line.line === request.delimiter ? done({ start: index, end: next }) : again(next);
  });
}
