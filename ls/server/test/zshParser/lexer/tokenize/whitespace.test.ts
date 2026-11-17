import { describe, expect, test } from 'vitest';
import { tokenSummaries } from './helper';

describe('Lexer.tokenize', () => {
  describe('空白を読み取る場合', () => {
    test('空白とタブの連続を1つのwhitespaceトークンにまとめる', () => {
      expect(
        tokenSummaries('a \t  b').map((token) => ({
          kind: token.kind,
          value: token.value,
        })),
      ).toEqual([
        { kind: 'word', value: 'a' },
        { kind: 'whitespace', value: ' \t  ' },
        { kind: 'word', value: 'b' },
        { kind: 'eof', value: '' },
      ]);
    });
  });
});
