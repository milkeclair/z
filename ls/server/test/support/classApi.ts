import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { globSync } from 'glob';

const repository = path.resolve(__dirname, '../../../..');

const publicClassFiles = ['lib/cls/process.zsh', 'lib/cls/method/process.zsh'];
const fullClassFiles = globSync('lib/cls/**/*.zsh', { cwd: repository, nodir: true });

/** 実装の関数コメントを、テスト用プロジェクトでもそのまま索引化する。 */
export function writeClassApi(root: string, includeInternals = false): string {
  const classFiles = includeInternals ? fullClassFiles : publicClassFiles;
  const functions = [...classFiles, 'lib/arg/process.zsh'];
  const source = functions
    .toSorted()
    .map((file) => readFileSync(path.join(repository, file), 'utf8'))
    .join('\n');
  const filename = path.join(root, 'class-api.zsh');

  writeFileSync(filename, source);

  return filename;
}
