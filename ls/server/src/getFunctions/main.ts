import { globSync } from 'glob';
import path from 'path';
import fs from 'fs';
import { functionRegex } from './regex';
import { Func } from './type';

export function getZshFunctions(projectRoot: string): Func[] {
  const files = globSync('**/*.zsh', { cwd: projectRoot, ignore: ['ls/**'] });
  const functions: Func[] = [];

  for (const file of files) {
    const filePath = path.join(projectRoot, file);
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');

    lines.forEach((line, i) => {
      const match = line.match(functionRegex);

      if (match) {
        functions.push({
          name: match[1],
          file: file,
          line: i + 1,
        });
      }
    });
  }

  return functions;
}
