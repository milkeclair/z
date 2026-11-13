import { removeHereDocQuotes, hereDocEnd, doubleEscape } from './heredoc';

export type DelimiterKind = 'single' | 'dollarSingle' | 'double' | 'backtick' | 'paren' | 'arrayParen' | 'patternParen' | 'brace' | 'arithmetic' | 'condition';

type CasePhase = 'header' | 'pattern' | 'body';
type Frame = {
  readonly kind: DelimiterKind;
  readonly cases: readonly CasePhase[];
  readonly commandStart: boolean;
  readonly hereDocs?: readonly { readonly delimiter: string; readonly quoted: boolean; readonly stripTabs: boolean }[];
};

const backtick = String.fromCharCode(96);

/** Read a balanced lexical region; return its exclusive end or null at EOF. */
export function delimitedEnd(text: string, start: number, kind: DelimiterKind, mode: 'shell' | 'hereDocWord' = 'shell'): number | null {
  const stack: Frame[] = [{ kind, cases: [], commandStart: true }];
  let index = start + (kind === 'arithmetic' || kind === 'condition' || kind === 'dollarSingle' ? 2 : 1);
  while (index < text.length && stack.length > 0) {
    const frame = stack[stack.length - 1];
    const char = text[index];
    const next = text[index + 1];
    const update = (value: Frame): void => { stack[stack.length - 1] = value; };
    const push = (value: DelimiterKind, length: number): void => {
      stack.push({ kind: value, cases: [], commandStart: true });
      index += length;
    };
    if (frame.kind === 'single' || frame.kind === 'dollarSingle') {
      if (char === '\\' && frame.kind === 'dollarSingle') index += 2;
      else {
        if (char === "'") stack.pop();
        index += 1;
      }
      continue;
    }
    if (char === '\\') { index += 2; continue; }
    if (frame.kind === 'double' && char === '"' || frame.kind === 'backtick' && char === backtick) {
      stack.pop(); index += 1; continue;
    }
    if (char === '$' && next === '(') {
      if (text[index + 2] === '(') push('arithmetic', 3);
      else push('paren', 2);
      continue;
    }
    if (char === '$' && next === '{') { push('brace', 2); continue; }
    if (frame.kind === 'double') {
      if (char === backtick) push('backtick', 1);
      else index += 1;
      continue;
    }
    if (next === '(' && frame.kind !== 'arithmetic' && frame.kind !== 'patternParen' &&
      (char === '<' || char === '>' || char === '=' && (index === 0 || ' =\t\r\n('.includes(text[index - 1])))) {
      push('paren', 2);
      continue;
    }
    if (char === '$' && next === "'") { push('dollarSingle', 2); continue; }
    if (char === "'") { push('single', 1); continue; }
    if (char === '"') { push('double', 1); continue; }
    if (char === backtick) { push('backtick', 1); continue; }
    if (frame.kind === 'brace') {
      if (char === '{') push('brace', 1);
      else { if (char === '}') stack.pop(); index += 1; }
      continue;
    }
    if (mode === 'shell' && (frame.kind === 'paren' || frame.kind === 'backtick') && text.startsWith('<<', index) && !text.startsWith('<<<', index)) {
      const header = hereDocHeader(text, index);
      if (header) {
        update({ ...frame, hereDocs: [...(frame.hereDocs ?? []), { delimiter: header.delimiter, quoted: header.quoted, stripTabs: header.stripTabs }] });
        index = header.end;
        continue;
      }
    }
    if (char === '\n' && frame.hereDocs?.length) {
      index += 1;
      for (const request of frame.hereDocs) {
        const ending = hereDocEnd(text, index, request);
        if (!ending) return null;
        index = ending.end;
      }
      update({ ...frame, hereDocs: [], commandStart: true });
      continue;
    }
    if (frame.kind === 'condition' && text.startsWith(']]', index)) {
      stack.pop(); index += 2; continue;
    }
    if (frame.kind === 'arithmetic' && text.startsWith('))', index)) {
      stack.pop(); index += 2; continue;
    }
    if (text.startsWith('[[', index)) { push('condition', 2); continue; }
    if (text.startsWith('((', index) && frame.kind !== 'arithmetic' && frame.kind !== 'patternParen' && frame.kind !== 'arrayParen') { push('arithmetic', 2); continue; }
    const phase = frame.cases[frame.cases.length - 1];
    if (char === '(' && phase !== 'pattern') {
      push(frame.kind === 'condition' || frame.kind === 'arithmetic' || frame.kind === 'arrayParen' || frame.kind === 'patternParen' ? 'patternParen' : 'paren', 1);
      continue;
    }
    if (char === ')') {
      if (phase === 'pattern') update({ ...frame, cases: [...frame.cases.slice(0, -1), 'body'], commandStart: true });
      else stack.pop();
      index += 1; continue;
    }
    if (char === '#' && (frame.kind === 'paren' || frame.kind === 'backtick' || frame.kind === 'arrayParen') && (index === 0 || ' \t\r\n;|&('.includes(text[index - 1]))) {
      while (index < text.length && text[index] !== '\n') index += 1;
      continue;
    }
    if (phase === 'body' && (text.startsWith(';;', index) || text.startsWith(';&', index) || text.startsWith(';|', index))) {
      update({ ...frame, cases: [...frame.cases.slice(0, -1), 'pattern'], commandStart: true });
      index += 2; continue;
    }
    if (';\n|&'.includes(char)) {
      update({ ...frame, commandStart: true }); index += 1; continue;
    }
    if (' \t\r'.includes(char)) { index += 1; continue; }
    const wordStart = index;
    while (index < text.length && !' \t\r\n;|&(){}\\"\'$'.includes(text[index]) && text[index] !== backtick) index += 1;
    if (wordStart === index) { index += 1; continue; }
    const word = text.slice(wordStart, index);
    let cases = frame.cases;
    if ((frame.kind === 'paren' || frame.kind === 'backtick') && word === 'case' && frame.commandStart) cases = [...cases, 'header'];
    else if (word === 'in' && phase === 'header') cases = [...cases.slice(0, -1), 'pattern'];
    else if (word === 'esac' && cases.length > 0 && (frame.commandStart || phase === 'pattern')) cases = cases.slice(0, -1);
    update({ ...frame, cases, commandStart: ['if', 'while', 'until', 'then', 'do', 'else', 'elif', '!'].includes(word) });
  }
  return stack.length === 0 ? Math.min(index, text.length) : null;
}

export function hereDocDelimiter(raw: string, stripTabs = false): { readonly delimiter: string; readonly quoted: boolean } {
  return removeHereDocQuotes(raw, stripTabs, (start) => delimitedEnd(raw, start + 1, 'paren', 'hereDocWord'));
}

/** Read a quoted delimiter header without treating its contents as shell syntax. */
export function hereDocHeader(text: string, start: number): { readonly delimiter: string; readonly quoted: boolean; readonly stripTabs: boolean; readonly end: number } | null {
  const stripTabs = text[start + 2] === '-';
  let index = start + (stripTabs ? 3 : 2);
  while (index < text.length) {
    if (text[index] === ' ' || text[index] === '\t') index += 1;
    else if (text[index] === '\\' && text[index + 1] === '\n') index += 2;
    else if (text[index] === '\\' && text[index + 1] === '\r' && text[index + 2] === '\n') index += 3;
    else break;
  }
  if (text[index] === '#') return null;
  const first = index;
  let quote = '';
  while (index < text.length) {
    const char = text[index];
    if (quote !== "'" && quote !== 'ansi' && char === '$' && (text[index + 1] === '(' || text[index + 1] === '{')) {
      const end = delimitedEnd(text, index + 1, text[index + 1] === '(' ? 'paren' : 'brace', 'hereDocWord');
      if (end === null) return null;
      index = end;
      continue;
    }
    if (char === '\\' && quote !== "'") {
      if (quote === 'ansi' || !quote || doubleEscape(text[index + 1] ?? '')) index += 2;
      else index += 1;
    } else if (!quote && char === '$' && text[index + 1] === "'") { quote = 'ansi'; index += 2; }
    else if (quote) { if (char === (quote === 'ansi' ? "'" : quote)) quote = ''; index += 1; }
    else if (char === "'" || char === '"' || char.charCodeAt(0) === 96) { quote = char; index += 1; }
    else if (' \t\r\n;|&()<>'.includes(char)) break;
    else index += 1;
  }
  return index === first || quote ? null : { ...hereDocDelimiter(text.slice(first, index), stripTabs), stripTabs, end: index };
}
