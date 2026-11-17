import { List, Range } from 'immutable';
import { again, done, loop } from '../../../util/loop';
import { doubleEscape, hereDocEnd, removeHereDocQuotes } from './heredoc';

export type DelimiterKind =
  | 'single'
  | 'dollarSingle'
  | 'double'
  | 'backtick'
  | 'paren'
  | 'arrayParen'
  | 'patternParen'
  | 'brace'
  | 'arithmetic'
  | 'condition';
type CasePhase = 'header' | 'pattern' | 'body';
type HereDoc = {
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly stripTabs: boolean;
};
type Frame = {
  readonly kind: DelimiterKind;
  readonly cases: readonly CasePhase[];
  readonly commandStart: boolean;
  readonly hereDocs?: readonly HereDoc[];
};
type Progress = { readonly index: number; readonly frames: List<Frame> };
const backtick = String.fromCharCode(96);

function frameOf(kind: DelimiterKind): Frame {
  return { kind, cases: [], commandStart: true };
}
function move(progress: Progress, index: number): Progress {
  return { ...progress, index };
}
function open(progress: Progress, kind: DelimiterKind, width: number): Progress {
  return { index: progress.index + width, frames: progress.frames.push(frameOf(kind)) };
}
function close(progress: Progress, width: number): Progress {
  return { index: progress.index + width, frames: progress.frames.pop() };
}
function replace(progress: Progress, frame: Frame, index: number): Progress {
  return { index, frames: progress.frames.set(-1, frame) };
}
function pendingHereDocEnd(
  text: string,
  start: number,
  requests: readonly HereDoc[],
): number | null {
  return loop<{ readonly index: number; readonly offset: number }, number | null>(
    { index: 0, offset: start },
    (state) => {
      const request = requests[state.index];
      if (!request) {
        return done(state.offset);
      }
      const ending = hereDocEnd(text, state.offset, request);
      return ending ? again({ index: state.index + 1, offset: ending.end }) : done(null);
    },
  );
}
function nextCases(frame: Frame, word: string): readonly CasePhase[] {
  const phase = frame.cases.at(-1);
  if (
    (frame.kind === 'paren' || frame.kind === 'backtick') &&
    word === 'case' &&
    frame.commandStart
  ) {
    return [...frame.cases, 'header'];
  }
  if (word === 'in' && phase === 'header') {
    return [...frame.cases.slice(0, -1), 'pattern'];
  }
  if (word === 'esac' && frame.cases.length > 0 && (frame.commandStart || phase === 'pattern')) {
    return frame.cases.slice(0, -1);
  }
  return frame.cases;
}

/** 対応する区切りまで字句領域を読み、終端の直後の位置を返す。EOFならnullを返す。 */
export function delimitedEnd(
  text: string,
  start: number,
  kind: DelimiterKind,
  mode: 'shell' | 'hereDocWord' = 'shell',
): number | null {
  const width = kind === 'arithmetic' || kind === 'condition' || kind === 'dollarSingle' ? 2 : 1;
  return loop<Progress, number | null>(
    { index: start + width, frames: List([frameOf(kind)]) },
    (progress) => {
      const { index, frames } = progress;
      const frame = frames.last();
      if (!frame) {
        return done(Math.min(index, text.length));
      }
      if (index >= text.length) {
        return done(null);
      }
      const char = text[index],
        next = text[index + 1];
      if (frame.kind === 'single' || frame.kind === 'dollarSingle') {
        if (char === '\\' && frame.kind === 'dollarSingle') {
          return again(move(progress, index + 2));
        }
        return again(char === "'" ? close(progress, 1) : move(progress, index + 1));
      }
      if (char === '\\') {
        return again(move(progress, index + 2));
      }
      if (
        (frame.kind === 'double' && char === '"') ||
        (frame.kind === 'backtick' && char === backtick)
      ) {
        return again(close(progress, 1));
      }
      if (char === '$' && next === '(') {
        return again(
          text[index + 2] === '(' ? open(progress, 'arithmetic', 3) : open(progress, 'paren', 2),
        );
      }
      if (char === '$' && next === '{') {
        return again(open(progress, 'brace', 2));
      }
      if (frame.kind === 'double') {
        return again(char === backtick ? open(progress, 'backtick', 1) : move(progress, index + 1));
      }
      if (
        next === '(' &&
        frame.kind !== 'arithmetic' &&
        frame.kind !== 'patternParen' &&
        (char === '<' ||
          char === '>' ||
          (char === '=' && (index === 0 || ' =\t\r\n('.includes(text[index - 1]))))
      ) {
        return again(open(progress, 'paren', 2));
      }
      if (char === '$' && next === "'") {
        return again(open(progress, 'dollarSingle', 2));
      }
      if (char === "'") {
        return again(open(progress, 'single', 1));
      }
      if (char === '"') {
        return again(open(progress, 'double', 1));
      }
      if (char === backtick) {
        return again(open(progress, 'backtick', 1));
      }
      if (frame.kind === 'brace') {
        if (char === '{') {
          return again(open(progress, 'brace', 1));
        }
        return again(char === '}' ? close(progress, 1) : move(progress, index + 1));
      }
      if (
        mode === 'shell' &&
        (frame.kind === 'paren' || frame.kind === 'backtick') &&
        text.startsWith('<<', index) &&
        !text.startsWith('<<<', index)
      ) {
        const header = hereDocHeader(text, index);
        if (header) {
          const request = {
            delimiter: header.delimiter,
            quoted: header.quoted,
            stripTabs: header.stripTabs,
          };
          return again(
            replace(
              progress,
              { ...frame, hereDocs: [...(frame.hereDocs ?? []), request] },
              header.end,
            ),
          );
        }
      }
      if (char === '\n' && frame.hereDocs?.length) {
        const ending = pendingHereDocEnd(text, index + 1, frame.hereDocs);
        return ending === null
          ? done(null)
          : again(replace(progress, { ...frame, hereDocs: [], commandStart: true }, ending));
      }
      if (frame.kind === 'condition' && text.startsWith(']]', index)) {
        return again(close(progress, 2));
      }
      if (frame.kind === 'arithmetic' && text.startsWith('))', index)) {
        return again(close(progress, 2));
      }
      if (frame.kind !== 'condition' && text.startsWith('[[', index)) {
        return again(open(progress, 'condition', 2));
      }
      if (
        text.startsWith('((', index) &&
        frame.kind !== 'arithmetic' &&
        frame.kind !== 'patternParen' &&
        frame.kind !== 'arrayParen'
      ) {
        return again(open(progress, 'arithmetic', 2));
      }
      const phase = frame.cases.at(-1);
      if (char === '(' && phase !== 'pattern') {
        const nested =
          frame.kind === 'condition' ||
          frame.kind === 'arithmetic' ||
          frame.kind === 'arrayParen' ||
          frame.kind === 'patternParen'
            ? 'patternParen'
            : 'paren';
        return again(open(progress, nested, 1));
      }
      if (char === ')') {
        return again(
          phase === 'pattern'
            ? replace(
                progress,
                { ...frame, cases: [...frame.cases.slice(0, -1), 'body'], commandStart: true },
                index + 1,
              )
            : close(progress, 1),
        );
      }
      if (
        char === '#' &&
        (frame.kind === 'paren' || frame.kind === 'backtick' || frame.kind === 'arrayParen') &&
        (index === 0 || ' \t\r\n;|&('.includes(text[index - 1]))
      ) {
        const newline = text.indexOf('\n', index);
        return again(move(progress, newline < 0 ? text.length : newline));
      }
      if (
        phase === 'body' &&
        (text.startsWith(';;', index) ||
          text.startsWith(';&', index) ||
          text.startsWith(';|', index))
      ) {
        return again(
          replace(
            progress,
            { ...frame, cases: [...frame.cases.slice(0, -1), 'pattern'], commandStart: true },
            index + 2,
          ),
        );
      }
      if (';\n|&'.includes(char)) {
        return again(replace(progress, { ...frame, commandStart: true }, index + 1));
      }
      if (' \t\r'.includes(char)) {
        return again(move(progress, index + 1));
      }
      const end =
        Range(index, text.length).find(
          (offset) => ' \t\r\n;|&(){}\\"\'$'.includes(text[offset]) || text[offset] === backtick,
        ) ?? text.length;
      if (end === index) {
        return again(move(progress, index + 1));
      }
      const word = text.slice(index, end);
      return again(
        replace(
          progress,
          {
            ...frame,
            cases: nextCases(frame, word),
            commandStart: ['if', 'while', 'until', 'then', 'do', 'else', 'elif', '!'].includes(
              word,
            ),
          },
          end,
        ),
      );
    },
  );
}

export function hereDocDelimiter(
  raw: string,
  stripTabs = false,
): { readonly delimiter: string; readonly quoted: boolean } {
  return removeHereDocQuotes(raw, stripTabs, (start) =>
    delimitedEnd(raw, start + 1, 'paren', 'hereDocWord'),
  );
}

function skipHeaderWhitespace(text: string, start: number): number {
  return loop(start, (index) => {
    if (index >= text.length) {
      return done(index);
    }
    if (text[index] === ' ' || text[index] === '\t') {
      return again(index + 1);
    }
    if (text[index] === '\\' && text[index + 1] === '\n') {
      return again(index + 2);
    }
    if (text[index] === '\\' && text[index + 1] === '\r' && text[index + 2] === '\n') {
      return again(index + 3);
    }
    return done(index);
  });
}

function headerWordEnd(text: string, start: number): number | null {
  return loop<{ readonly index: number; readonly quote: string }, number | null>(
    { index: start, quote: '' },
    (state) => {
      const { index, quote } = state;
      if (index >= text.length) {
        return done(quote ? null : index);
      }
      const char = text[index];
      if (
        quote !== "'" &&
        quote !== 'ansi' &&
        char === '$' &&
        (text[index + 1] === '(' || text[index + 1] === '{')
      ) {
        const end = delimitedEnd(
          text,
          index + 1,
          text[index + 1] === '(' ? 'paren' : 'brace',
          'hereDocWord',
        );
        return end === null ? done(null) : again({ ...state, index: end });
      }
      if (char === '\\' && quote !== "'") {
        const width = quote === 'ansi' || !quote || doubleEscape(text[index + 1] ?? '') ? 2 : 1;
        return again({ ...state, index: index + width });
      }
      if (!quote && char === '$' && text[index + 1] === "'") {
        return again({ quote: 'ansi', index: index + 2 });
      }
      if (quote) {
        return again({
          index: index + 1,
          quote: char === (quote === 'ansi' ? "'" : quote) ? '' : quote,
        });
      }
      if (char === "'" || char === '"' || char.charCodeAt(0) === 96) {
        return again({ quote: char, index: index + 1 });
      }
      return ' \t\r\n;|&()<>'.includes(char) ? done(index) : again({ ...state, index: index + 1 });
    },
  );
}

/** 内容をシェル構文として扱わず、引用された終端名を読む。 */
export function hereDocHeader(
  text: string,
  start: number,
): {
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly stripTabs: boolean;
  readonly end: number;
} | null {
  const stripTabs = text[start + 2] === '-';
  const first = skipHeaderWhitespace(text, start + (stripTabs ? 3 : 2));
  if (text[first] === '#') {
    return null;
  }
  const end = headerWordEnd(text, first);
  return end === null || end === first
    ? null
    : { ...hereDocDelimiter(text.slice(first, end), stripTabs), stripTabs, end };
}
