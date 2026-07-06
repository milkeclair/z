import { describe, expect, test } from 'vitest';
import { tokenSummaries } from './helper';

describe('tokenize@line', () => {
  test('LFをnewlineトークンとして読む', () => {
    const newline = tokenSummaries('a\nb').find((token) => token.kind === 'newline');

    expect(newline).toEqual({
      kind: 'newline',
      value: '\n',
      range: {
        start: { offset: 1, line: 0, character: 1 },
        end: { offset: 2, line: 1, character: 0 },
      },
      quoted: false,
      quoteKind: 'none',
      operatorKind: null,
      sourceFile: 'test.zsh',
    });
  });

  test('CRLFを1つのnewlineトークンとして読む', () => {
    const newline = tokenSummaries('a\r\nb').find((token) => token.kind === 'newline');

    expect(newline).toEqual({
      kind: 'newline',
      value: '\r\n',
      range: {
        start: { offset: 1, line: 0, character: 1 },
        end: { offset: 3, line: 1, character: 0 },
      },
      quoted: false,
      quoteKind: 'none',
      operatorKind: null,
      sourceFile: 'test.zsh',
    });
  });

  test('CRをnewlineトークンとして読む', () => {
    const newline = tokenSummaries('a\rb').find((token) => token.kind === 'newline');

    expect(newline).toEqual({
      kind: 'newline',
      value: '\r',
      range: {
        start: { offset: 1, line: 0, character: 1 },
        end: { offset: 2, line: 1, character: 0 },
      },
      quoted: false,
      quoteKind: 'none',
      operatorKind: null,
      sourceFile: 'test.zsh',
    });
  });

  test('バックスラッシュとLFをcontinuationトークンとして読む', () => {
    expect(
      tokenSummaries('echo \\\nfoo').map((token) => ({
        kind: token.kind,
        value: token.value,
        range: token.range,
      })),
    ).toEqual([
      {
        kind: 'word',
        value: 'echo',
        range: {
          start: { offset: 0, line: 0, character: 0 },
          end: { offset: 4, line: 0, character: 4 },
        },
      },
      {
        kind: 'whitespace',
        value: ' ',
        range: {
          start: { offset: 4, line: 0, character: 4 },
          end: { offset: 5, line: 0, character: 5 },
        },
      },
      {
        kind: 'continuation',
        value: '\\\n',
        range: {
          start: { offset: 5, line: 0, character: 5 },
          end: { offset: 7, line: 1, character: 0 },
        },
      },
      {
        kind: 'word',
        value: 'foo',
        range: {
          start: { offset: 7, line: 1, character: 0 },
          end: { offset: 10, line: 1, character: 3 },
        },
      },
      {
        kind: 'eof',
        value: '',
        range: {
          start: { offset: 10, line: 1, character: 3 },
          end: { offset: 10, line: 1, character: 3 },
        },
      },
    ]);
  });
});
