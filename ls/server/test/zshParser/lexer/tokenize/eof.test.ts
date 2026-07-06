import { describe, expect, test } from 'vitest';
import { TestSourceFile, tokenize } from './helper';

describe('tokenize@eof', () => {
  test('空文字列はEOFトークンのみを返す', () => {
    expect(tokenize('')).toEqual({
      tokens: [
        {
          kind: 'eof',
          value: '',
          sourceFile: TestSourceFile,
          range: {
            start: { offset: 0, line: 0, character: 0 },
            end: { offset: 0, line: 0, character: 0 },
          },
          quoted: false,
          quoteKind: 'none',
          operatorKind: undefined,
        },
      ],
      diagnostics: [],
    });
  });
});
