import { describe, expect, test } from 'vitest';
import { tokenSummaries } from './helper';

describe('tokenize@whitespace', () => {
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
