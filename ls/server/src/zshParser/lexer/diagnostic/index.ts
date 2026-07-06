import type { QuoteKind, SourcePosition } from '../token';

type LexerDiagnosticKind = 'unclosedQuote';

type DiagnosticRange = {
  readonly start: SourcePosition;
  readonly end: SourcePosition;
};

export type LexerDiagnostic = {
  readonly kind: LexerDiagnosticKind;
  readonly message: string;
  readonly sourceFile: string;
  readonly range: DiagnosticRange;
  readonly quoteKind?: QuoteKind;
};

export function createLexerDiagnostic({
  kind,
  message,
  sourceFile,
  start,
  end,
  quoteKind,
}: {
  readonly kind: LexerDiagnostic['kind'];
  readonly message: string;
  readonly sourceFile: string;
  readonly start: SourcePosition;
  readonly end: SourcePosition;
  readonly quoteKind?: QuoteKind;
}): LexerDiagnostic {
  return {
    kind,
    message,
    sourceFile,
    range: { start, end },
    quoteKind,
  };
}
