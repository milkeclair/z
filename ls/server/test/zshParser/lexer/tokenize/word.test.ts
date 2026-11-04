import { describe, expect, test } from 'vitest';
import { TestSourceFile, tokenSummaries } from './helper';

describe('tokenize@word', () => {
  test('引用されていないwordを水平空白で区切る', () => {
    expect(tokenSummaries('echo foo')).toEqual([
      {
        kind: 'word',
        value: 'echo',
        range: {
          start: { offset: 0, line: 0, character: 0 },
          end: { offset: 4, line: 0, character: 4 },
        },
        quoted: false,
        quoteKind: 'none',
        operatorKind: null,
        sourceFile: TestSourceFile,
      },
      {
        kind: 'whitespace',
        value: ' ',
        range: {
          start: { offset: 4, line: 0, character: 4 },
          end: { offset: 5, line: 0, character: 5 },
        },
        quoted: false,
        quoteKind: 'none',
        operatorKind: null,
        sourceFile: TestSourceFile,
      },
      {
        kind: 'word',
        value: 'foo',
        range: {
          start: { offset: 5, line: 0, character: 5 },
          end: { offset: 8, line: 0, character: 8 },
        },
        quoted: false,
        quoteKind: 'none',
        operatorKind: null,
        sourceFile: TestSourceFile,
      },
      {
        kind: 'eof',
        value: '',
        range: {
          start: { offset: 8, line: 0, character: 8 },
          end: { offset: 8, line: 0, character: 8 },
        },
        quoted: false,
        quoteKind: 'none',
        operatorKind: null,
        sourceFile: TestSourceFile,
      },
    ]);
  });

  test('word内のハッシュはcommentにしない', () => {
    expect(tokenSummaries('foo#bar')).toEqual([
      {
        kind: 'word',
        value: 'foo#bar',
        range: {
          start: { offset: 0, line: 0, character: 0 },
          end: { offset: 7, line: 0, character: 7 },
        },
        quoted: false,
        quoteKind: 'none',
        operatorKind: null,
        sourceFile: TestSourceFile,
      },
      {
        kind: 'eof',
        value: '',
        range: {
          start: { offset: 7, line: 0, character: 7 },
          end: { offset: 7, line: 0, character: 7 },
        },
        quoted: false,
        quoteKind: 'none',
        operatorKind: null,
        sourceFile: TestSourceFile,
      },
    ]);
  });
});
