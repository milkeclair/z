import type { CommentNode } from '../../zshParser/ast';
import { rangeWithinText } from '../../zshParser/parser/range';
import type { ParameterDoc } from './types';
import { commentPayload } from '../directive';

function isDigit(char: string): boolean { return char >= '0' && char <= '9'; }
function isNameStart(char: string): boolean {
  return char === '_' || char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z';
}
export function parseParameter(comment: CommentNode): ParameterDoc | null {
  const payload = commentPayload(comment);
  const text = payload.text;
  if (!text.startsWith('$')) return null;
  let cursor = 1;
  const first = text[cursor] ?? '';
  if (isDigit(first)) while (isDigit(text[cursor] ?? '')) cursor += 1;
  else if (first === '@' || first === '*') cursor += 1;
  else if (isNameStart(first)) {
    cursor += 1;
    while (isNameStart(text[cursor] ?? '') || isDigit(text[cursor] ?? '')) cursor += 1;
  } else return null;
  const name = text.slice(1, cursor);
  const markerEnd = cursor;
  const optional = text[cursor] === '?';
  if (optional) cursor += 1;
  while (text[cursor] === ' ' || text[cursor] === '\t') cursor += 1;
  if (text[cursor] !== ':') return null;
  const base = {
    range: comment.range, raw: comment.text, optional, description: text.slice(cursor + 1).trim(),
    markerRange: rangeWithinText(comment.range, comment.text, payload.start, payload.start + markerEnd),
  };
  if (isDigit(first)) {
    const position = Number(name);
    if (!Number.isSafeInteger(position) || position < 1) return null;
    return { ...base, kind: 'positionalParameterDoc', position };
  }
  if (first === '@' || first === '*') return { ...base, kind: 'restParameterDoc', parameter: first };
  return { ...base, kind: 'namedParameterDoc', name };
}
