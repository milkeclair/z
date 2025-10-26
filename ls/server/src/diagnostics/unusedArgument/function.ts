import { functionDefRegex } from '../regex';

export function findFunctionDefinition(lines: string[], funcName: string): number {
  for (let i = 0; i < lines.length; i++) {
    const match = lines[i].match(functionDefRegex);

    if (match && match[0].startsWith(funcName)) return i;
  }

  return -1;
}

export function findFunctionEnd(lines: string[], startLine: number): number {
  let braceCount = 0;
  let foundStart = false;

  for (let i = startLine; i < lines.length; i++) {
    const line = lines[i];

    for (const char of line) {
      if (char === '{') {
        braceCount++;
        foundStart = true;
      } else if (char === '}') {
        braceCount--;
        if (foundStart && braceCount === 0) return i;
      }
    }
  }

  return lines.length - 1;
}
