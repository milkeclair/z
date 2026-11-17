import { globSync } from 'glob';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import { astContractViolations } from './contracts';

const repoRoot = resolve(__dirname, '../../../../..');
const files = globSync('**/*.zsh', {
  cwd: repoRoot,
  nodir: true,
  ignore: ['.git/**', 'ls/node_modules/**', 'plans/**'],
}).toSorted();

describe('Parser.parse', () => {
  describe('リポジトリ内のZshファイルを解析する場合', () => {
    test('検証対象のzshファイルが存在する', () => {
      expect(files.length).toBeGreaterThan(0);
    });

    test('全ファイルのtoken・座標・raw・構造・共有参照が一致する', () => {
      for (const file of files) {
        const sourceFile = resolve(repoRoot, file);
        const input = readFileSync(sourceFile, 'utf8');

        const lexed = Lexer.tokenize(input, { sourceFile });
        const parsed = Parser.parse(lexed.tokens, { sourceFile, path: sourceFile });

        expect.soft(lexed.diagnostics, file).toEqual([]);
        expect.soft(parsed.diagnostics, file).toEqual([]);
        expect.soft(astContractViolations(parsed.ast, parsed.tokens, input), file).toEqual([]);
      }
    });
  });
});
