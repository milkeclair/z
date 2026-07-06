import type { OperatorKind } from '../token';

export type OperatorDefinition = {
  readonly value: string;
  readonly kind: OperatorKind;
};

type SpecialCharacterSet = {
  readonly empty: string;
  readonly space: string;
  readonly tab: string;
  readonly lineFeed: string;
  readonly carriageReturn: string;
  readonly carriageReturnLineFeed: string;
  readonly backslash: string;
  readonly backslashLineFeed: string;
  readonly hash: string;
  readonly singleQuote: string;
  readonly doubleQuote: string;
  readonly dollarSingleQuoteStart: string;
};

export const SpecialCharacters: SpecialCharacterSet = {
  empty: '',
  space: ' ',
  tab: '\t',
  lineFeed: '\n',
  carriageReturn: '\r',
  carriageReturnLineFeed: '\r\n',
  backslash: '\\',
  backslashLineFeed: '\\\n',
  hash: '#',
  singleQuote: "'",
  doubleQuote: '"',
  dollarSingleQuoteStart: "$'",
};

export const Operators: readonly OperatorDefinition[] = [
  { value: '&>>', kind: 'redirect' },
  { value: '<<<', kind: 'redirect' },
  { value: '<<-', kind: 'redirect' },
  { value: '&&', kind: 'andIf' },
  { value: '||', kind: 'orIf' },
  { value: '|&', kind: 'pipeErr' },
  { value: ';;', kind: 'doubleSemicolon' },
  { value: ';&', kind: 'caseFallthrough' },
  { value: ';|', kind: 'caseContinue' },
  { value: '[[', kind: 'conditionStart' },
  { value: ']]', kind: 'conditionEnd' },
  { value: '((', kind: 'arithmeticStart' },
  { value: '))', kind: 'arithmeticEnd' },
  { value: '>>', kind: 'redirect' },
  { value: '<<', kind: 'redirect' },
  { value: '>|', kind: 'redirect' },
  { value: '<>', kind: 'redirect' },
  { value: '<&', kind: 'redirect' },
  { value: '>&', kind: 'redirect' },
  { value: '&>', kind: 'redirect' },
  { value: '(', kind: 'leftParen' },
  { value: ')', kind: 'rightParen' },
  { value: '{', kind: 'leftBrace' },
  { value: '}', kind: 'rightBrace' },
  { value: ';', kind: 'semicolon' },
  { value: '|', kind: 'pipe' },
  { value: '&', kind: 'background' },
  { value: '<', kind: 'redirect' },
  { value: '>', kind: 'redirect' },
];
