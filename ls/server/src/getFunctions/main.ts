import { globSync } from 'glob';
import path from 'path';
import fs from 'fs';
import { functionRegex } from './regex';
import { Func, FuncContent } from './type';

export function extractZFunctions(content: string): FuncContent[] {
  const functions: FuncContent[] = [];
  const lines = content.split('\n');

  lines.forEach((line, index) => {
    const match = line.match(functionRegex);

    if (match) {
      functions.push({
        name: match[1],
        line: index + 1,
      });
    }
  });

  return functions;
}

export function getAllZFunctions(projectRoot: string): Func[] {
  const files = globSync('**/*.zsh', { cwd: projectRoot, ignore: ['ls/**'] });
  const functions: Func[] = [];

  for (const file of files) {
    const filePath = path.join(projectRoot, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    const extracted = extractZFunctions(content);

    extracted.forEach((f) => {
      functions.push({
        name: f.name,
        line: f.line,
        file,
      });
    });
  }

  return functions;
}
