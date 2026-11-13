import type { ParserDiagnosticKind } from '../../ast';
import type { Token } from '../../lexer';
import { createParserDiagnostic } from '../diagnostic';
import { rangeFromTokens } from '../range';
import { currentToken } from './cursor';
import type { ParseState } from './types';

export function addDiagnostic({
  state,
  kind,
  message,
  tokens,
}: {
  readonly state: ParseState;
  readonly kind: ParserDiagnosticKind;
  readonly message: string;
  readonly tokens: readonly Token[];
}): ParseState {
  if (state.stopped) return state;
  return {
    ...state,
    diagnostics: [
      ...state.diagnostics,
      createParserDiagnostic({
        kind,
        message,
        sourceFile: state.sourceFile,
        range: rangeFromTokens(tokens, currentToken(state).range),
      }),
    ],
  };
}
