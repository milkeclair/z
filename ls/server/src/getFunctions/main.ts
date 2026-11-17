import fs from 'fs';
import { globSync } from 'glob';
import path from 'path';
import { extractFunctionArgs } from './argument';
import { functionRegex } from './regex';
import { Func, FuncContent } from './type';

export function extractZFunctions(content: string): FuncContent[] {
  const functions: FuncContent[] = [];
  const lines = content.split('\n');

  lines.forEach((line, index) => {
    const match = line.match(functionRegex);

    if (match) {
      const args = extractFunctionArgs(lines, index);

      functions.push({
        name: match[1],
        line: index + 1,
        args,
      });
    }
  });

  return functions;
}

export function getAllZFunctions(projectRoot: string): Func[] {
  const files = globSync('**/*.zsh', { cwd: projectRoot });
  const functions: Func[] = [];

  for (const file of files) {
    const filePath = path.join(projectRoot, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    const extracted = extractZFunctions(content);

    extracted.forEach((definition) => {
      functions.push({
        name: definition.name,
        line: definition.line,
        file,
        args: definition.args,
      });
    });
  }

  return functions;
}
