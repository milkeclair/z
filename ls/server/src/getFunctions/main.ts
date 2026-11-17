import { globSync } from 'glob';
import fs from 'node:fs';
import path from 'node:path';
import { extractFunctionArgs } from './argument';
import { functionRegex } from './regex';
import type { Func, FuncContent } from './type';

export function extractZFunctions(content: string): FuncContent[] {
  const lines = content.split('\n');
  return lines.flatMap((line, index) => {
    const match = line.match(functionRegex);
    return match
      ? [{ name: match[1], line: index + 1, args: extractFunctionArgs(lines, index) }]
      : [];
  });
}

export function getAllZFunctions(projectRoot: string): Func[] {
  return globSync('**/*.zsh', { cwd: projectRoot }).flatMap((file) => {
    const content = fs.readFileSync(path.join(projectRoot, file), 'utf-8');
    return extractZFunctions(content).map((definition) => ({ ...definition, file }));
  });
}
