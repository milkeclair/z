import { describe, expect, test } from 'vitest';
import { diagnosticSummaries, tokenSummaries } from './helper';

function wordSummaries(input: string) {
  return tokenSummaries(input)
    .filter((token) => token.kind === 'word')
    .map((token) => ({
      value: token.value,
      quoted: token.quoted,
      quoteKind: token.quoteKind,
    }));
}

describe('tokenize@quote', () => {
  test('一重引用符を区切り文字ごとwordとして読む', () => {
    expect(wordSummaries("'abc'")).toEqual([
      { value: "'abc'", quoted: true, quoteKind: 'single' },
    ]);
  });

  test('二重引用符内の空白をwordの一部として読む', () => {
    expect(wordSummaries('"a b"')).toEqual([
      { value: '"a b"', quoted: true, quoteKind: 'double' },
    ]);
  });

  test('ドル付き一重引用符をwordとして読む', () => {
    expect(wordSummaries("$'\\n'")).toEqual([
      { value: "$'\\n'", quoted: true, quoteKind: 'dollarSingle' },
    ]);
  });

  test('複数種類の引用符を含むwordはmixedとして読む', () => {
    expect(wordSummaries('a"b"\'c\'$\'d\'')).toEqual([
      { value: 'a"b"\'c\'$\'d\'', quoted: true, quoteKind: 'mixed' },
    ]);
  });

  test('引用符内の特殊記号はcommentやoperatorにしない', () => {
    expect(
      tokenSummaries('"a;b # c"').map((token) => ({
        kind: token.kind,
        value: token.value,
        quoteKind: token.quoteKind,
      })),
    ).toEqual([
      { kind: 'word', value: '"a;b # c"', quoteKind: 'double' },
      { kind: 'eof', value: '', quoteKind: 'none' },
    ]);
  });

  test('未終了の二重引用符はwordと診断を返す', () => {
    expect(wordSummaries('"x')).toEqual([
      { value: '"x', quoted: true, quoteKind: 'double' },
    ]);
    expect(diagnosticSummaries('"x')).toEqual([
      {
        kind: 'unclosedQuote',
        message: 'Unclosed double quote.',
        range: {
          start: { offset: 0, line: 0, character: 0 },
          end: { offset: 2, line: 0, character: 2 },
        },
        quoteKind: 'double',
        sourceFile: 'test.zsh',
      },
    ]);
  });

  test('未終了の一重引用符はwordと診断を返す', () => {
    expect(wordSummaries("'x")).toEqual([
      { value: "'x", quoted: true, quoteKind: 'single' },
    ]);
    expect(diagnosticSummaries("'x")).toEqual([
      {
        kind: 'unclosedQuote',
        message: 'Unclosed single quote.',
        range: {
          start: { offset: 0, line: 0, character: 0 },
          end: { offset: 2, line: 0, character: 2 },
        },
        quoteKind: 'single',
        sourceFile: 'test.zsh',
      },
    ]);
  });

  test('未終了のドル付き一重引用符はwordと診断を返す', () => {
    expect(wordSummaries("$'x")).toEqual([
      { value: "$'x", quoted: true, quoteKind: 'dollarSingle' },
    ]);
    expect(diagnosticSummaries("$'x")).toEqual([
      {
        kind: 'unclosedQuote',
        message: 'Unclosed dollarSingle quote.',
        range: {
          start: { offset: 0, line: 0, character: 0 },
          end: { offset: 3, line: 0, character: 3 },
        },
        quoteKind: 'dollarSingle',
        sourceFile: 'test.zsh',
      },
    ]);
  });
});
