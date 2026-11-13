import { describe, expect, test } from 'vitest';
import { tokenSummaries } from './helper';

describe('tokenize@comment', () => {
  test('行頭のハッシュからcommentトークンを読む', () => {
    expect(
      tokenSummaries('# top').map((token) => ({
        kind: token.kind,
        value: token.value,
      })),
    ).toEqual([
      { kind: 'comment', value: '# top' },
      { kind: 'eof', value: '' },
    ]);
  });

  test('水平空白の後のハッシュからcommentトークンを読む', () => {
    expect(
      tokenSummaries('echo foo # comment').map((token) => ({
        kind: token.kind,
        value: token.value,
      })),
    ).toEqual([
      { kind: 'word', value: 'echo' },
      { kind: 'whitespace', value: ' ' },
      { kind: 'word', value: 'foo' },
      { kind: 'whitespace', value: ' ' },
      { kind: 'comment', value: '# comment' },
      { kind: 'eof', value: '' },
    ]);
  });

  test('commentは改行の手前で止まる', () => {
    expect(
      tokenSummaries('foo#bar # baz\nx').map((token) => ({
        kind: token.kind,
        value: token.value,
      })),
    ).toEqual([
      { kind: 'word', value: 'foo#bar' },
      { kind: 'whitespace', value: ' ' },
      { kind: 'comment', value: '# baz' },
      { kind: 'newline', value: '\n' },
      { kind: 'word', value: 'x' },
      { kind: 'eof', value: '' },
    ]);
  });

  test('parameter expansion内のハッシュはcommentにしない', () => {
    expect(
      tokenSummaries('echo ${#items[@]} && return 1').map((token) => ({
        kind: token.kind,
        value: token.value,
        operatorKind: token.operatorKind,
      })),
    ).toEqual([
      { kind: 'word', value: 'echo', operatorKind: null },
      { kind: 'whitespace', value: ' ', operatorKind: null },
      { kind: 'word', value: '$', operatorKind: null },
      { kind: 'operator', value: '{', operatorKind: 'leftBrace' },
      { kind: 'word', value: '#items[@]', operatorKind: null },
      { kind: 'operator', value: '}', operatorKind: 'rightBrace' },
      { kind: 'whitespace', value: ' ', operatorKind: null },
      { kind: 'operator', value: '&&', operatorKind: 'andIf' },
      { kind: 'whitespace', value: ' ', operatorKind: null },
      { kind: 'word', value: 'return', operatorKind: null },
      { kind: 'whitespace', value: ' ', operatorKind: null },
      { kind: 'word', value: '1', operatorKind: null },
      { kind: 'eof', value: '', operatorKind: null },
    ]);
  });
});
