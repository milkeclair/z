import type { ParserDiagnosticKind } from '../ast';
import type { SourceRange } from '../lexer';

export type ParserDiagnostic = {
  readonly kind: ParserDiagnosticKind;
  readonly message: string;
  readonly sourceFile: string;
  readonly range: SourceRange;
};

export function createParserDiagnostic({
  kind,
  message,
  sourceFile,
  range,
}: {
  readonly kind: ParserDiagnosticKind;
  readonly message: string;
  readonly sourceFile: string;
  readonly range: SourceRange;
}): ParserDiagnostic {
  return {
    kind,
    message,
    sourceFile,
    range,
  };
}
