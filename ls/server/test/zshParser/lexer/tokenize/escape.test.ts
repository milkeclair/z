import { describe, expect, test } from 'vitest';
import { tokenSummaries } from './helper';

function wordSummaries(input: string) {
  return tokenSummaries(input)
    .filter((token) => token.kind === 'word')
    .map((token) => ({
      value: token.value,
      quoted: token.quoted,
      quoteKind: token.quoteKind,
    }));
}

describe('Lexer.tokenize', () => {
  describe('エスケープを読み取る場合', () => {
    test('エスケープされた空白はword内に残す', () => {
      expect(wordSummaries('a\\ b')).toEqual([
        { value: 'a\\ b', quoted: true, quoteKind: 'backslash' },
      ]);
    });

    test('エスケープされたハッシュはcommentにしない', () => {
      expect(wordSummaries('\\#x')).toEqual([
        { value: '\\#x', quoted: true, quoteKind: 'backslash' },
      ]);
    });

    test('エスケープされたoperatorはoperatorにしない', () => {
      expect(wordSummaries('\\;')).toEqual([
        { value: '\\;', quoted: true, quoteKind: 'backslash' },
      ]);
    });

    test('末尾のバックスラッシュもwordとして返す', () => {
      expect(wordSummaries('abc\\')).toEqual([
        { value: 'abc\\', quoted: true, quoteKind: 'backslash' },
      ]);
    });
  });
});
