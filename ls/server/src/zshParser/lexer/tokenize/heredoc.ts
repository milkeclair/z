import { hereDocEnd } from '../delimiter/heredoc';
import type { Cursor } from '../cursor';
import { advance, position } from '../cursor';
import { createToken } from '../token';
import type { Token } from '../token';
import type { LexerDiagnostic } from '../diagnostic';

export type HereDocRequest = {
  readonly operatorOffset: number; readonly delimiter: string; readonly quoted: boolean; readonly stripTabs: boolean;
};
export { hereDocDelimiter } from '../delimiter';
export function readHereDocuments(cursor: Cursor, requests: readonly HereDocRequest[], sourceFile: string) {
  const tokens: Token[] = []; const diagnostics: LexerDiagnostic[] = [];
  let current = cursor;
  for (const request of requests) {
    const start = position(current);
    const text = current.text;
    const endingRange = hereDocEnd(text, start.offset, request);
    const delimiterStart = endingRange?.start ?? -1;
    const delimiterEnd = endingRange?.end ?? text.length;
    const bodyEnd = delimiterStart < 0 ? text.length : delimiterStart;
    const body = advance(current, bodyEnd - start.offset);
    const metadata = { ...request, closed: delimiterStart >= 0 };
    tokens.push({ ...createToken({ kind: 'hereDocBody', value: body.value, sourceFile, start, end: position(body.cursor) }), hereDoc: metadata });
    current = body.cursor;
    if (delimiterStart >= 0) {
      const ending = advance(current, delimiterEnd - delimiterStart);
      tokens.push({ ...createToken({ kind: 'hereDocEnd', value: ending.value, sourceFile, start: position(current), end: position(ending.cursor) }), hereDoc: metadata });
      current = ending.cursor;
    } else diagnostics.push({ kind: 'unclosedHereDocument', message: 'Missing here-document delimiter ' + request.delimiter, sourceFile, range: { start, end: position(current) } });
  }
  return { cursor: current, tokens, diagnostics };
}
