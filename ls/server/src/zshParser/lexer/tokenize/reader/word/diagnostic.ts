import type { LexerDiagnostic } from '../../../diagnostic';
import { createLexerDiagnostic } from '../../../diagnostic';
import type { QuoteKind, SourcePosition } from '../../../token';

export function createUnclosedQuoteDiagnostic({
  sourceFile,
  start,
  end,
  quote,
}: {
  readonly sourceFile: string;
  readonly start: SourcePosition;
  readonly end: SourcePosition;
  readonly quote: QuoteKind;
}): LexerDiagnostic {
  return createLexerDiagnostic({
    kind: 'unclosedQuote',
    message: `Unclosed ${quote} quote.`,
    sourceFile,
    start,
    end,
    quoteKind: quote,
  });
}
