import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { globSync } from 'glob';
import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import { astContractViolations } from './contracts';

const repoRoot = resolve(__dirname, '../../../../..');
const files = globSync('**/*.zsh', {
  cwd: repoRoot, nodir: true, ignore: ['.git/**', 'ls/node_modules/**'],
}).sort();

describe('parse@allZFiles', () => {
  test('検証対象のzshファイルが存在する', () => {
    expect(files.length).toBeGreaterThan(0);
  });
  test.each(files)('%sのtoken、座標、raw、構造、共有参照が一致する', (file) => {
    const sourceFile = resolve(repoRoot, file);
    const input = readFileSync(sourceFile, 'utf8');
    const lexed = Lexer.tokenize(input, { sourceFile });
    const parsed = Parser.parse(lexed.tokens, { sourceFile, path: sourceFile });
    expect(lexed.diagnostics).toEqual([]);
    expect(parsed.diagnostics).toEqual([]);
    expect(astContractViolations(parsed.ast, parsed.tokens, input)).toEqual([]);
  });
});
