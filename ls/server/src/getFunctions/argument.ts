import { FuncArg } from '../getFunctions/type';
import { NAMED_ARG_POSITION } from '../getFunctions/constant';
import { positionalArgRegex, namedArgRegex } from './regex';
import { COMMENT_CHAR } from './constant';

function parsePositionalArg(line: string): FuncArg | null {
  const match = line.match(positionalArgRegex);
  if (!match) return null;

  const [, posStr, optionalMarker, name] = match;

  return {
    position: parseInt(posStr, 10),
    name: name.trim(),
    optional: optionalMarker === '?',
    isNamed: false,
  };
}

function parseNamedArg(line: string): FuncArg | null {
  const match = line.match(namedArgRegex);
  if (!match) return null;

  const [, argName, optionalMarker] = match;

  return {
    position: NAMED_ARG_POSITION,
    name: argName,
    optional: optionalMarker === '?',
    isNamed: true,
  };
}

function sortArgs(args: FuncArg[]): FuncArg[] {
  // [
  //   { position: 1, isNamed: false },
  //   { position: 2, isNamed: false },
  //   { position: -1, isNamed: true, name: 'option1' },
  //   { position: -1, isNamed: true, name: 'option2' },
  // ]
  return args.sort((a, b) => {
    if (a.isNamed && b.isNamed) return 0;
    if (a.isNamed) return 1;
    if (b.isNamed) return -1;
    return a.position - b.position;
  });
}

export function extractFunctionArgs(lines: string[], functionLineIndex: number): FuncArg[] {
  const args: FuncArg[] = [];

  const outOfCommentLine = (line: string): boolean => {
    return !line.trim().startsWith(COMMENT_CHAR);
  };

  for (let i = functionLineIndex - 1; i >= 0; i--) {
    const line = lines[i];

    if (outOfCommentLine(line)) break;

    const positionalArg = parsePositionalArg(line);
    if (positionalArg) {
      args.push(positionalArg);
      continue;
    }

    const namedArg = parseNamedArg(line);
    if (namedArg) {
      args.push(namedArg);
    }
  }

  return sortArgs(args);
}
