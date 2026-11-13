import { createLexicalContext } from './context';
import type { LexicalContext } from './context';
import { SpecialCharacters } from '../character';
import { createCursor } from '../cursor';
import { eof, position } from '../cursor';
import type { LexerDiagnostic } from '../diagnostic';
import type { Token, TokenizeOptions } from '../token';
import { createToken } from '../token';
import { isWordBoundary } from './boundary';
import { Reader } from './reader';
import { readTokenizeStep } from './step';
import type { Cursor } from '../cursor';

export type TokenizeState = {
  readonly context: LexicalContext;
  readonly cursor: Cursor;
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
};

export type TokenizeResult = {
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
};

export function tokenize(input: string, options: TokenizeOptions = {}): TokenizeResult {
  const sourceFile = options.sourceFile ?? SpecialCharacters.empty;
  const cursor = createCursor(input);
  const reader = Reader({ sourceFile });
  const tokens: Token[] = [];
  const diagnostics: LexerDiagnostic[] = [];
  let result: TokenizeState = {
    cursor, tokens: [], diagnostics: [],
    context: createLexicalContext(),
  };
  while (!eof(result.cursor) || result.context.readHereDocs) {
    result = readTokenizeStep({ state: result, sourceFile, reader, isWordBoundary });
    tokens.push(...result.tokens);
    diagnostics.push(...result.diagnostics);
  }
  const end = position(result.cursor);
  for (let context: LexicalContext | null = result.context; context; context = context.parent) {
    for (const request of context.pendingHereDocs) diagnostics.push({
    kind: 'unclosedHereDocument', message: 'Missing here-document delimiter ' + request.delimiter,
    sourceFile, range: { start: end, end },
    });
  }

  return {
    tokens: [
      ...tokens,
      createToken({
        kind: 'eof',
        value: SpecialCharacters.empty,
        sourceFile,
        start: end,
        end,
      }),
    ],
    diagnostics,
  };
}
