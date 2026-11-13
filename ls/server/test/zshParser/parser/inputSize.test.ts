import { describe, expect, test } from 'vitest';
import { parse, simpleCommandFromItem } from './helper';

describe('parse@inputSize', () => {
  test('置換の処理上限が外側へ伝わり、後続をUnknownとして保持する', () => {
    const expression = 'echo $('.repeat(100) + 'true' + ')'.repeat(100);
    const result = parse(expression + '\necho after\n' + expression);
    expect(result.diagnostics.map((item) => item.kind)).toEqual(['nestingLimitExceeded']);
    expect(result.ast.body.items.at(-1)?.sublist.kind).toBe('unknown');
  });

  test('alwaysの連鎖にも入れ子上限を適用する', () => {
    const source = '{ : }' + ' always { : }'.repeat(5000);
    const result = parse(source);
    expect(result.diagnostics.map((item) => item.kind)).toEqual(['nestingLimitExceeded']);
    expect(result.ast.eof.range.end.offset).toBe(source.length);
  });

  test('既定の入れ子上限より下では全体を解析し、上限で一件の診断へ切り替える', () => {
    expect(parse('{ '.repeat(63) + 'true' + '; }'.repeat(63)).diagnostics).toEqual([]);
    expect(parse('{ '.repeat(64) + 'true' + '; }'.repeat(64)).diagnostics.map((item) => item.kind)).toEqual(['nestingLimitExceeded']);
  });

  test('1万引数のcommandを解析する', () => {
    const result = parse('echo ' + Array.from({ length: 10000 }, () => 'arg').join(' '));
    expect(result.diagnostics).toEqual([]);
    expect(simpleCommandFromItem(result.ast.body.items[0]).arguments).toHaveLength(10000);
  });

  test('過度な文法の入れ子を処理上限診断と部分ASTへ変換する', () => {
    const source = '{ '.repeat(1000) + 'echo ok' + '; }'.repeat(1000);
    const result = parse(source);
    expect(result.diagnostics.map((item) => item.kind)).toEqual(['nestingLimitExceeded']);
    expect(result.ast.eof.range.end.offset).toBe(source.length);
  });

  test('長い論理式とpipelineを水平方向の再帰なしで解析する', () => {
    for (const operator of [' && ', ' | ']) {
      const result = parse(Array.from({ length: 5000 }, () => 'true').join(operator));
      expect(result.diagnostics).toEqual([]);
      expect(result.ast.body.items).toHaveLength(1);
    }
  });

  test('コメント付き1000関数を再走査の再帰なしで解析する', () => {
    const source = Array.from({ length: 1000 }, (_, index) =>
      '# docs\nf' + index + '() { print ok }\n').join('');
    const result = parse(source);
    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1000);
    expect(result.ast.comments).toHaveLength(1000);
  });

  test.each([3000, 10000])('%i行の入力をNode.jsのスタック上限に達せず解析する', (count) => {
    const source = 'echo ok\n'.repeat(count);
    const result = parse(source);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(count);
    expect(result.ast.eof.range.start.offset).toBe(source.length);
    expect(simpleCommandFromItem(result.ast.body.items[count - 1]).arguments[0].raw).toBe('ok');
  }, 20000);

  test('長い単語をスタック上限に達せず解析する', () => {
    const word = 'x'.repeat(20000);
    const result = parse(`echo ${word}\n`);

    expect(result.diagnostics).toEqual([]);
    expect(simpleCommandFromItem(result.ast.body.items[0]).arguments[0].raw).toBe(word);
  });
});
