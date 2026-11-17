import { horizontalWhitespaceEnd, textWhileEnd } from '../../util/text';
import type { CommentNode } from '../../zshParser/ast';
import { rangeWithinText } from '../../zshParser/parser/range';
import { commentPayload } from '../directive';
import { parseCodeParameterType } from './parameterType';
import type { ParameterDoc } from './types';

function isDigit(char: string): boolean {
  return char >= '0' && char <= '9';
}
function isNameStart(char: string): boolean {
  return char === '_' || (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z');
}
export function parseParameter(comment: CommentNode): ParameterDoc | null {
  const payload = commentPayload(comment);
  const text = payload.text;
  if (!text.startsWith('$')) {
    return null;
  }
  const first = text[1] ?? '';
  const markerEnd = isDigit(first)
    ? textWhileEnd(text, 1, isDigit)
    : first === '@' || first === '*'
      ? 2
      : isNameStart(first)
        ? textWhileEnd(text, 2, (char) => isNameStart(char) || isDigit(char))
        : null;
  if (markerEnd === null) {
    return null;
  }
  const name = text.slice(1, markerEnd);
  const optional = text[markerEnd] === '?';
  const beforeType = horizontalWhitespaceEnd(text, markerEnd + (optional ? 1 : 0));
  const annotation = text[beforeType] === '[' ? parseCodeParameterType(text, beforeType) : null;
  const cursor = annotation ? horizontalWhitespaceEnd(text, annotation.end) : beforeType;
  if (text[cursor] !== ':') {
    return null;
  }
  const valueType: 'code' | undefined = annotation ? 'code' : undefined;
  const base = {
    ...(valueType
      ? {
          valueType,
          ...(annotation?.literalValues.length ? { literalValues: annotation.literalValues } : {}),
        }
      : {}),
    range: comment.range,
    raw: comment.text,
    optional,
    description: text.slice(cursor + 1).trim(),
    markerRange: rangeWithinText(
      comment.range,
      comment.text,
      payload.start,
      payload.start + markerEnd,
    ),
  };
  if (isDigit(first)) {
    const position = Number(name);
    if (!Number.isSafeInteger(position) || position < 1) {
      return null;
    }
    return { ...base, kind: 'positionalParameterDoc', position };
  }
  if (first === '@' || first === '*') {
    return { ...base, kind: 'restParameterDoc', parameter: first };
  }
  return { ...base, kind: 'namedParameterDoc', name };
}
