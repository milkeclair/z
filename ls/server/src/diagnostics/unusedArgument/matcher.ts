import { isCommentLine } from '../comment';
import { positionalArgRegex, variablePatternRegex, providePatternRegex } from './regex';

function isAllArgsUsed(line: string, argName: string): boolean {
  const isPositionalArgument = (name: string): boolean => {
    return /^\d+$/.test(name);
  };

  return /\$@/.test(line) && isPositionalArgument(argName);
}

function isPositionalArgUsed(line: string, argName: string): boolean {
  return positionalArgRegex(argName).test(line);
}

function isNamedArgUsed(line: string, argName: string): boolean {
  const trimmedLine = line.trim();

  if (variablePatternRegex(argName).test(line)) return true;

  const notLocal = !trimmedLine.startsWith('local ');
  if (notLocal && providePatternRegex(argName).test(line)) {
    return true;
  }

  return false;
}

export function isArgumentUsedInFunction(
  lines: string[],
  argName: string,
  startLine: number,
  endLine: number
): boolean {
  const indexOffset = 1;
  for (let i = startLine + indexOffset; i <= endLine; i++) {
    const line = lines[i];

    if (isCommentLine(line.trim())) continue;

    if (isAllArgsUsed(line, argName)) return true;
    if (isPositionalArgUsed(line, argName)) return true;
    if (isNamedArgUsed(line, argName)) return true;
  }

  return false;
}
