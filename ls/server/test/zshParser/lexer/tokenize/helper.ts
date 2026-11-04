import { Lexer } from '../../../../src/zshParser/lexer';
import type { TokenizeOptions } from '../../../../src/zshParser/lexer';

export const TestSourceFile = 'test.zsh';

export function tokenize(
  input: string,
  options: TokenizeOptions = { sourceFile: TestSourceFile },
) {
  return Lexer.tokenize(input, options);
}

export function tokenSummaries(input: string, options?: TokenizeOptions) {
  return tokenize(input, options).tokens.map((token) => ({
    kind: token.kind,
    value: token.value,
    range: token.range,
    quoted: token.quoted,
    quoteKind: token.quoteKind,
    operatorKind: token.operatorKind ?? null,
    sourceFile: token.sourceFile,
  }));
}

export function diagnosticSummaries(input: string, options?: TokenizeOptions) {
  return tokenize(input, options).diagnostics.map((diagnostic) => ({
    kind: diagnostic.kind,
    message: diagnostic.message,
    range: diagnostic.range,
    quoteKind: diagnostic.quoteKind ?? null,
    sourceFile: diagnostic.sourceFile,
  }));
}
