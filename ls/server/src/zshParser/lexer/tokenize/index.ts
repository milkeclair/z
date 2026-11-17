import { SpecialCharacters } from '../character';
import type { Cursor } from '../cursor';
import { createCursor, eof, position } from '../cursor';
import type { LexerDiagnostic } from '../diagnostic';
import type { Token, TokenizeOptions } from '../token';
import { createToken } from '../token';
import { isWordBoundary } from './boundary';
import type { LexicalContext } from './context';
import { createLexicalContext } from './context';
import { Reader } from './reader';
import { readTokenizeStep } from './step';

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
  const initial: TokenizeState = {
    cursor,
    tokens: [],
    diagnostics: [],
    context: createLexicalContext(),
  };

  const chunks = Array.from(readTokens(initial, sourceFile, reader));

  return {
    tokens: chunks.flatMap((chunk) => chunk.tokens),
    diagnostics: chunks.flatMap((chunk) => chunk.diagnostics),
  };
}

function* readTokens(
  state: TokenizeState,
  sourceFile: string,
  reader: ReturnType<typeof Reader>,
): Generator<TokenizeResult> {
  while (!eof(state.cursor) || state.context.readHereDocs) {
    state = readTokenizeStep({ state, sourceFile, reader, isWordBoundary });
    yield { tokens: state.tokens, diagnostics: state.diagnostics };
  }

  const end = position(state.cursor);
  yield {
    tokens: [
      createToken({ kind: 'eof', value: SpecialCharacters.empty, sourceFile, start: end, end }),
    ],
    diagnostics: Array.from(unclosedHereDocuments(state.context, sourceFile, end)),
  };
}

function* unclosedHereDocuments(
  context: LexicalContext | null,
  sourceFile: string,
  end: ReturnType<typeof position>,
): Generator<LexerDiagnostic> {
  while (context) {
    for (const request of context.pendingHereDocs) {
      yield {
        kind: 'unclosedHereDocument',
        message: 'Missing here-document delimiter ' + request.delimiter,
        sourceFile,
        range: { start: end, end },
      };
    }

    context = context.parent;
  }
}
