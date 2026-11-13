import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import { TestSourceFile } from './helper';

describe('parse@facade', () => {
  test('Parser.parseはASTを返す', () => {
    const tokenized = Lexer.tokenize('echo ok\n', { sourceFile: TestSourceFile });
    const options = {
      sourceFile: TestSourceFile,
      path: TestSourceFile,
    };

    expect(Parser.parse(tokenized.tokens, options).ast.kind).toBe('file');
  });
});
