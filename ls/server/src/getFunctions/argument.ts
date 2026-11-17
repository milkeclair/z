import { Range } from 'immutable';
import { COMMENT_CHAR, NAMED_ARG_POSITION } from './constant';
import { namedArgRegex, positionalArgRegex, specialArgRegex } from './regex';
import { FuncArg } from './type';

function parsePositionalArg(line: string): FuncArg | null {
  const match = line.match(positionalArgRegex);
  if (!match) {
    return null;
  }

  const [, posStr, optionalMarker, name] = match;

  return {
    position: parseInt(posStr, 10),
    name: name.trim(),
    optional: optionalMarker === '?',
    isNamed: false,
  };
}

function parseSpecialArg(line: string): FuncArg | null {
  const match = line.match(specialArgRegex);
  if (!match) {
    return null;
  }

  const [, argName, optionalMarker, _description] = match;

  return {
    position: Number.MAX_SAFE_INTEGER,
    name: argName,
    optional: optionalMarker === '?',
    isNamed: false,
  };
}

function parseNamedArg(line: string): FuncArg | null {
  const match = line.match(namedArgRegex);
  if (!match) {
    return null;
  }

  const [, argName, optionalMarker] = match;

  return {
    position: NAMED_ARG_POSITION,
    name: argName,
    optional: optionalMarker === '?',
    isNamed: true,
  };
}

function sortArgs(args: readonly FuncArg[]): FuncArg[] {
  return args.toSorted((left, right) => {
    if (left.isNamed && right.isNamed) return 0;
    if (left.isNamed) return 1;
    if (right.isNamed) return -1;
    return left.position - right.position;
  });
}
export function extractFunctionArgs(
  lines: readonly string[],
  functionLineIndex: number,
): FuncArg[] {
  const args = Range(functionLineIndex - 1, -1, -1)
    .takeWhile((index) => lines[index].trim().startsWith(COMMENT_CHAR))
    .map(
      (index) =>
        parsePositionalArg(lines[index]) ??
        parseSpecialArg(lines[index]) ??
        parseNamedArg(lines[index]),
    )
    .filter((argument): argument is FuncArg => argument !== null)
    .toArray();
  return sortArgs(args);
}
