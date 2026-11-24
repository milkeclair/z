import { horizontalWhitespaceEnd, textWhileEnd } from '../../util/text';
import type { CommentNode } from '../../zshParser/ast';
import { rangeWithinText } from '../../zshParser/parser/range';
import { commentPayload } from '../directive';
import { parseCodeParameterType } from './parameterType';
import type { ClassReferenceType, ParameterDoc } from './types';

function isDigit(char: string): boolean {
  return char >= '0' && char <= '9';
}

function isNameStart(char: string): boolean {
  return char === '_' || (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z');
}

function parameterMarkerEnd(text: string, first: string): number | null {
  if (isDigit(first)) {
    return textWhileEnd(text, 1, isDigit);
  }

  if (first === '@' || first === '*') {
    return 2;
  }

  return isNameStart(first)
    ? textWhileEnd(text, 2, (char) => isNameStart(char) || isDigit(char))
    : null;
}

export function parseParameter(comment: CommentNode): ParameterDoc | null {
  const payload = commentPayload(comment);
  const text = payload.text;

  if (!text.startsWith('$')) {
    return null;
  }

  const first = text[1] ?? '';
  const markerEnd = parameterMarkerEnd(text, first);

  if (markerEnd === null) {
    return null;
  }

  const name = text.slice(1, markerEnd);
  const optional = text[markerEnd] === '?';
  const beforeType = horizontalWhitespaceEnd(text, markerEnd + (optional ? 1 : 0));
  const annotation = text[beforeType] === '[' ? parseCodeParameterType(text, beforeType) : null;
  const classMatch =
    !annotation && first !== '@' && first !== '*'
      ? /^\[([A-Za-z_][A-Za-z_0-9]*)<(read|write|owner)>\]/.exec(text.slice(beforeType))
      : null;
  const access = classMatch?.[2];
  const classReference: ClassReferenceType | undefined =
    classMatch && (access === 'read' || access === 'write' || access === 'owner')
      ? { className: classMatch[1], access }
      : undefined;
  const typeEnd = annotation?.end ?? beforeType + (classMatch?.[0].length ?? 0);
  const cursor = horizontalWhitespaceEnd(text, typeEnd);

  if (text[cursor] !== ':') {
    return null;
  }

  const valueType: 'code' | undefined = annotation ? 'code' : undefined;
  const base = {
    ...(classReference ? { classReference } : {}),
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
