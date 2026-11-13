import { delimitedEnd } from '../../../lexer/delimiter';
import type { VariableReferenceNode } from '../../../ast';
import { rangeWithinText } from '../../range';
import { createExpansionNode } from '../expansionNode';
import {
  createVariableNameNode,
  isNameStart,
  readNameEnd,
} from '../variableName';
import type { ExpansionReadResult, WordPartState } from './types';

const Empty = '';
const Dollar = '$';
const LeftBrace = '{';
const RightBrace = '}';
const LeftParen = '(';
const RightParen = ')';
const Hash = '#';
const SpecialParameterChars = new Set(['@', '*', '?', '!', '$', '-']);

export function readExpansion(state: WordPartState): ExpansionReadResult | null {
  if (state.text.charCodeAt(state.index) === 96) {
    const end = delimitedEnd(state.text.slice(0, state.end), state.index, 'backtick') ?? state.end;
    return { node: createExpansionNode({ kind: 'commandSubstitution', raw: state.text.slice(state.index, end),
      range: rangeWithinText(state.range, state.text, state.index, end), readBody: state.readBody }), nextIndex: end };
  } else if (state.quote === 'none' && ['<', '>', '='].includes(state.text[state.index]) && state.text[state.index + 1] === LeftParen &&
    (state.text[state.index] !== '=' || state.index === state.start || state.text[state.index - 1] === '=' || state.processStarts?.has(state.index))) {
    const end = delimitedEnd(state.text.slice(0, state.end), state.index + 1, 'paren') ?? state.end;
    const raw = state.text.slice(state.index, end);
    const range = rangeWithinText(state.range, state.text, state.index, end);
    return { node: {
      kind: 'processSubstitution', raw, range,
      direction: raw[0] === '<' ? 'input' : raw[0] === '>' ? 'output' : 'file',
      body: state.readBody?.(raw, range) ?? null,
    }, nextIndex: end };
  } else if (state.text[state.index] !== Dollar) {
    return null;
  } else if (state.text[state.index + 1] === LeftBrace) {
    return readParameterExpansion(state);
  } else if (
    state.text[state.index + 1] === LeftParen &&
    state.text[state.index + 2] === LeftParen
  ) {
    return readArithmeticExpansion(state);
  } else if (state.text[state.index + 1] === LeftParen) {
    return readCommandSubstitution(state);
  } else {
    return readSpecialParameterExpansion(state) ?? readVariableReference(state);
  }
}

function readParameterExpansion(state: WordPartState): ExpansionReadResult {
  const closeIndex = findMatchingCharacter({
    text: state.text,
    index: state.index + Dollar.length,
    max: state.end,
    open: LeftBrace,
    close: RightBrace,
    depth: 0,
  });
  const end = closeIndex === null ? state.end : closeIndex + RightBrace.length;

  return {
    node: createExpansionNode({
      readBody: state.readBody,
      kind: 'parameterExpansion',
      range: rangeWithinText(state.range, state.text, state.index, end),
      raw: state.text.slice(state.index, end),
    }),
    nextIndex: end,
  };
}

function readArithmeticExpansion(state: WordPartState): ExpansionReadResult {
  const end = delimitedEnd(state.text.slice(0, state.end), state.index + 1, 'arithmetic') ?? state.end;

  return {
    node: createExpansionNode({
      readBody: state.readBody,
      kind: 'arithmeticExpansion',
      range: rangeWithinText(state.range, state.text, state.index, end),
      raw: state.text.slice(state.index, end),
    }),
    nextIndex: end,
  };
}

function readCommandSubstitution(state: WordPartState): ExpansionReadResult {
  const closeIndex = findMatchingCharacter({
    text: state.text,
    index: state.index + Dollar.length,
    max: state.end,
    open: LeftParen,
    close: RightParen,
    depth: 0,
  });
  const end = closeIndex === null ? state.end : closeIndex + RightParen.length;

  return {
    node: createExpansionNode({
      readBody: state.readBody,
      kind: 'commandSubstitution',
      range: rangeWithinText(state.range, state.text, state.index, end),
      raw: state.text.slice(state.index, end),
    }),
    nextIndex: end,
  };
}

function findMatchingCharacter({
  text,
  index,
  max,
  open,
  close,
  depth,
}: {
  readonly text: string;
  readonly index: number;
  readonly max: number;
  readonly open: string;
  readonly close: string;
  readonly depth: number;
}): number | null {
  const kind = open === LeftBrace ? 'brace' : 'paren';
  const end = delimitedEnd(text.slice(0, max), index, kind);
  return end === null ? null : end - 1;
}

function readVariableReference(state: WordPartState): ExpansionReadResult | null {
  const nameStart = state.index + Dollar.length;

  if (!isNameStart(state.text[nameStart] ?? Empty)) {
    return null;
  } else {
    const nameEnd = readNameEnd({
      value: state.text,
      index: nameStart + 1,
      max: state.end,
    });
    const name = createVariableNameNode({
      value: state.text.slice(nameStart, nameEnd),
      range: rangeWithinText(state.range, state.text, nameStart, nameEnd),
    });

    return {
      node: {
        kind: 'variableReference',
        range: rangeWithinText(state.range, state.text, state.index, nameEnd),
        sigil: '$',
        name,
      } satisfies VariableReferenceNode,
      nextIndex: nameEnd,
    };
  }
}

function readSpecialParameterExpansion(state: WordPartState): ExpansionReadResult | null {
  const parameterStart = state.index + Dollar.length;
  const end = specialParameterEnd({
    text: state.text,
    parameterStart,
    max: state.end,
  });

  if (end === null) {
    return null;
  } else {
    return {
      node: createExpansionNode({
      readBody: state.readBody,
        kind: 'parameterExpansion',
        range: rangeWithinText(state.range, state.text, state.index, end),
        raw: state.text.slice(state.index, end),
      }),
      nextIndex: end,
    };
  }
}

function specialParameterEnd({
  text,
  parameterStart,
  max,
}: {
  readonly text: string;
  readonly parameterStart: number;
  readonly max: number;
}): number | null {
  const char = text[parameterStart] ?? Empty;

  if (parameterStart >= max) {
    return null;
  } else if (isAsciiDigit(char)) {
    return readDigitsEnd({
      text,
      index: parameterStart + 1,
      max,
    });
  } else if (char === Hash) {
    return hashParameterEnd({
      text,
      parameterStart,
      max,
    });
  } else if (SpecialParameterChars.has(char)) {
    return parameterStart + 1;
  } else {
    return null;
  }
}

function hashParameterEnd({
  text,
  parameterStart,
  max,
}: {
  readonly text: string;
  readonly parameterStart: number;
  readonly max: number;
}): number {
  const afterHash = parameterStart + Hash.length;
  const next = text[afterHash] ?? Empty;

  if (isNameStart(next)) {
    return readNameEnd({
      value: text,
      index: afterHash + 1,
      max,
    });
  } else if (isAsciiDigit(next)) {
    return readDigitsEnd({
      text,
      index: afterHash + 1,
      max,
    });
  } else {
    return afterHash;
  }
}

function readDigitsEnd({
  text,
  index,
  max,
}: {
  readonly text: string;
  readonly index: number;
  readonly max: number;
}): number {
  let cursor = index;
  while (cursor < max && isAsciiDigit(text[cursor] ?? Empty)) cursor += 1;
  return cursor;
}

function isAsciiDigit(char: string): boolean {
  return char >= '0' && char <= '9';
}
