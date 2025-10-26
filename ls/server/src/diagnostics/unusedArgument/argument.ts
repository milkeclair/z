import { FuncArg } from '../../getFunctions/type';
import { isCommentLine } from '../comment';
import { argRegex } from './regex';

export function argName(arg: FuncArg): string {
  return arg.isNamed ? arg.name : arg.position.toString();
}

export function argDisplayName(arg: FuncArg): string {
  return arg.isNamed ? arg.name : '$' + arg.position;
}

export function findArgDefinitionLine(lines: string[], arg: FuncArg, funcDefLine: number): number {
  for (let i = funcDefLine - 1; i >= 0; i--) {
    const line = lines[i];
    const outOfComment = !isCommentLine(line.trim());
    if (outOfComment) break;

    if (argRegex(arg).test(line)) return i;
  }

  return -1;
}
