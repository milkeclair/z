type TokenKind =
  | 'word'
  | 'operator'
  | 'comment'
  | 'whitespace'
  | 'newline'
  | 'continuation'
  | 'eof';

export type OperatorKind =
  | 'leftParen'
  | 'rightParen'
  | 'leftBrace'
  | 'rightBrace'
  | 'semicolon'
  | 'doubleSemicolon'
  | 'caseFallthrough'
  | 'caseContinue'
  | 'andIf'
  | 'orIf'
  | 'pipe'
  | 'pipeErr'
  | 'background'
  | 'redirect'
  | 'conditionStart'
  | 'conditionEnd'
  | 'arithmeticStart'
  | 'arithmeticEnd';

export type QuoteKind = 'none' | 'single' | 'double' | 'dollarSingle' | 'backslash' | 'mixed';

export type SourcePosition = {
  readonly offset: number;
  readonly line: number;
  readonly character: number;
};

type SourceRange = {
  readonly start: SourcePosition;
  readonly end: SourcePosition;
};

export type Token = {
  readonly kind: TokenKind;
  readonly value: string;
  readonly sourceFile: string;
  readonly range: SourceRange;
  readonly quoted: boolean;
  readonly quoteKind: QuoteKind;
  readonly operatorKind?: OperatorKind;
};

export type TokenizeOptions = {
  readonly sourceFile?: string;
};

export function createToken({
  kind,
  value,
  sourceFile,
  start,
  end,
  quoted = false,
  quoteKindValue = 'none',
  operatorKind,
}: {
  readonly kind: Token['kind'];
  readonly value: string;
  readonly sourceFile: string;
  readonly start: SourcePosition;
  readonly end: SourcePosition;
  readonly quoted?: boolean;
  readonly quoteKindValue?: QuoteKind;
  readonly operatorKind?: OperatorKind;
}): Token {
  return {
    kind,
    value,
    sourceFile,
    range: { start, end },
    quoted,
    quoteKind: quoteKindValue,
    operatorKind,
  };
}

export function quoteKind(current: QuoteKind, next: QuoteKind): QuoteKind {
  if (current === 'none') {
    return next;
  } else if (current === next) {
    return current;
  } else {
    return 'mixed';
  }
}
