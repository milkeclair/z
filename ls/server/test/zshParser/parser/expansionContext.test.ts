import { describe, expect, test } from 'vitest';
import { parse, simpleCommandFromItem } from './helper';

describe('parse@expansionContext', () => {

  test('算術展開の連続する括弧を内部の式として保持する', () => {
    const result = parse('echo $(( ((1)+2) ))');
    expect(result.diagnostics).toEqual([]);
    expect(simpleCommandFromItem(result.ast.body.items[0]).arguments[0]).toMatchObject({
      raw: '$(( ((1)+2) ))', parts: [{ kind: 'arithmeticExpansion', raw: '$(( ((1)+2) ))' }],
    });
  });
  test('未終端backtick内部の診断も元の範囲内に収まる', () => {
    const source = 'echo ' + String.fromCharCode(96) + 'printf "';
    const result = parse(source);
    expect(result.diagnostics.length).toBeGreaterThan(0);
    expect(result.diagnostics.every((item) =>
      item.range.start.offset >= 0 && item.range.end.offset <= source.length &&
      item.range.start.offset <= item.range.end.offset)).toBe(true);
  });

  test('隣接する置換とsubshellの閉じ括弧を別の所有者へ渡す', () => {
    const result = parse('(echo $(print x))');
    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(result.ast.body.items[0].sublist).toMatchObject({ first: { first: {
      kind: 'subshellCommand', body: { items: [{ sublist: { first: { first: { arguments: [{ raw: '$(print x)' }] } } } }] },
    } } });
  });

  test('backtickのコマンド置換も本体をASTとして保持する', () => {
    const raw = String.fromCharCode(96) + 'printf "%s" "a b"' + String.fromCharCode(96);
    const result = parse('echo ' + raw);
    expect(result.diagnostics).toEqual([]);
    expect(simpleCommandFromItem(result.ast.body.items[0]).arguments[0]).toMatchObject({
      raw, parts: [{ kind: 'commandSubstitution', raw, body: { items: expect.any(Array) } }],
    });
  });

  test.each([
    'echo "$(printf "%s" "a b")"',
    'echo "$(printf \'%s\' \')\')"',
    'echo $(case x in x) print ok;; esac)',
  ])('引用と文法の終端を区別する: %s', (source) => {
    const result = parse(source);
    expect(result.diagnostics).toEqual([]);
    const command = simpleCommandFromItem(result.ast.body.items[0]);
    expect(command.arguments).toHaveLength(1);
    const argument = command.arguments[0];
    expect(argument.raw).toBe(source.slice(5));
    const raw = argument.raw.startsWith('"') ? argument.raw.slice(1, -1) : argument.raw;
    expect(argument.parts).toEqual(expect.arrayContaining([
      expect.objectContaining({ kind: 'commandSubstitution', raw }),
    ]));
  });
});
