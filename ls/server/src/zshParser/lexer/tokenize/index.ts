import { List } from 'immutable';
import { loop, again, done } from '../../../util/loop';
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
  type Progress = {
    readonly state: TokenizeState;
    readonly tokens: List<Token>;
    readonly diagnostics: List<LexerDiagnostic>;
  };
  const result = loop<Progress, Progress>(
    { state: initial, tokens: List(), diagnostics: List() },
    (progress) => {
      if (eof(progress.state.cursor) && !progress.state.context.readHereDocs) {
        return done(progress);
      }
      const next = readTokenizeStep({ state: progress.state, sourceFile, reader, isWordBoundary });
      return again({
        state: next,
        tokens: progress.tokens.concat(next.tokens),
        diagnostics: progress.diagnostics.concat(next.diagnostics),
      });
    },
  );
  const end = position(result.state.cursor);
  type FinalContext = {
    readonly context: LexicalContext | null;
    readonly diagnostics: List<LexerDiagnostic>;
  };
  const diagnostics = loop<FinalContext, List<LexerDiagnostic>>(
    { context: result.state.context, diagnostics: result.diagnostics },
    (progress) => {
      if (!progress.context) {
        return done(progress.diagnostics);
      }
      const unclosed = progress.context.pendingHereDocs.map(
        (request): LexerDiagnostic => ({
          kind: 'unclosedHereDocument',
          message: 'Missing here-document delimiter ' + request.delimiter,
          sourceFile,
          range: { start: end, end },
        }),
      );
      return again({
        context: progress.context.parent,
        diagnostics: progress.diagnostics.concat(unclosed),
      });
    },
  );
  return {
    tokens: result.tokens
      .push(
        createToken({ kind: 'eof', value: SpecialCharacters.empty, sourceFile, start: end, end }),
      )
      .toArray(),
    diagnostics: diagnostics.toArray(),
  };
}
