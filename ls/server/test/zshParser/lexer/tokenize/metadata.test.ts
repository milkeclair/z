import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../../src/zshParser/lexer';
import { tokenize } from './helper';

describe('tokenize@metadata', () => {
  test('ソースファイル名をトークンと診断に引き継ぐ', () => {
    const sourceFile = 'metadata.zsh';
    const result = tokenize('echo "x', { sourceFile });

    expect(result.tokens.map((token) => token.sourceFile)).toEqual([
      sourceFile,
      sourceFile,
      sourceFile,
      sourceFile,
    ]);
    expect(result.diagnostics.map((diagnostic) => diagnostic.sourceFile)).toEqual([
      sourceFile,
    ]);
  });

  test('ソースファイル名が未指定なら空文字列を使う', () => {
    const result = Lexer.tokenize('echo x');

    expect(result.tokens.map((token) => token.sourceFile)).toEqual(['', '', '', '']);
    expect(result.diagnostics).toEqual([]);
  });
});
