import { List } from 'immutable';
import type { Cursor } from '../cursor';
import { advance, position } from '../cursor';
import { hereDocEnd } from '../delimiter/heredoc';
import type { LexerDiagnostic } from '../diagnostic';
import type { Token } from '../token';
import { createToken } from '../token';

export type HereDocRequest = {
  readonly operatorOffset: number;
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly stripTabs: boolean;
};
export { hereDocDelimiter } from '../delimiter';
export function readHereDocuments(
  cursor: Cursor,
  requests: readonly HereDocRequest[],
  sourceFile: string,
) {
  const result = requests.reduce(
    (progress, request) => {
      const parsed = readHereDocument(progress.cursor, request, sourceFile);
      return {
        cursor: parsed.cursor,
        tokens: progress.tokens.concat(parsed.tokens),
        diagnostics: progress.diagnostics.concat(parsed.diagnostics),
      };
    },
    { cursor, tokens: List<Token>(), diagnostics: List<LexerDiagnostic>() },
  );
  return {
    cursor: result.cursor,
    tokens: result.tokens.toArray(),
    diagnostics: result.diagnostics.toArray(),
  };
}

function readHereDocument(
  cursor: Cursor,
  request: HereDocRequest,
  sourceFile: string,
): {
  readonly cursor: Cursor;
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly LexerDiagnostic[];
} {
  const start = position(cursor);
  const endingRange = hereDocEnd(cursor.text, start.offset, request);
  const delimiterStart = endingRange?.start ?? -1;
  const delimiterEnd = endingRange?.end ?? cursor.text.length;
  const bodyEnd = delimiterStart < 0 ? cursor.text.length : delimiterStart;
  const body = advance(cursor, bodyEnd - start.offset);
  const metadata = { ...request, closed: delimiterStart >= 0 };
  const bodyToken = {
    ...createToken({
      kind: 'hereDocBody',
      value: body.value,
      sourceFile,
      start,
      end: position(body.cursor),
    }),
    hereDoc: metadata,
  };
  if (delimiterStart < 0) {
    return {
      cursor: body.cursor,
      tokens: [bodyToken],
      diagnostics: [
        {
          kind: 'unclosedHereDocument',
          message: 'Missing here-document delimiter ' + request.delimiter,
          sourceFile,
          range: { start, end: position(body.cursor) },
        },
      ],
    };
  }
  const ending = advance(body.cursor, delimiterEnd - delimiterStart);
  const endToken = {
    ...createToken({
      kind: 'hereDocEnd',
      value: ending.value,
      sourceFile,
      start: position(body.cursor),
      end: position(ending.cursor),
    }),
    hereDoc: metadata,
  };
  return { cursor: ending.cursor, tokens: [bodyToken, endToken], diagnostics: [] };
}
