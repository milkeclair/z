import { describe, expect, test } from 'vitest';
import { commandFromItem, parse } from './helper';

describe('parse@opaqueCommand', () => {
  test('置換内部の]]で外側の条件を閉じない', () => {
    const source = '[[ $( [[ -n x ]] && print x ) == x ]]';
    const result = parse(source + ' && print yes');
    expect(result.diagnostics).toEqual([]);
    expect(commandFromItem(result.ast.body.items[0])).toMatchObject({ kind: 'opaqueCommand', syntax: 'condition', raw: source });
  });

  test('条件コマンドはunknown診断にせずopaqueCommandとして読む', () => {
    const result = parse('[[ -n $value ]] && echo ok\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command).toMatchObject({
      kind: 'opaqueCommand',
      syntax: 'condition',
      raw: '[[ -n $value ]]',
      close: {
        start: {
          offset: 13,
        },
      },
    });
  });

  test('算術コマンドはunknown診断にせずopaqueCommandとして読む', () => {
    const result = parse('(( count++ ))\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command).toMatchObject({
      kind: 'opaqueCommand',
      syntax: 'arithmetic',
      raw: '(( count++ ))',
      close: {
        start: {
          offset: 11,
        },
      },
    });
  });

  test('条件コマンドは改行を含んで終端まで読む', () => {
    const result = parse('[[ -n $value &&\n  -n $other ]]\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(command).toMatchObject({
      kind: 'opaqueCommand',
      syntax: 'condition',
      raw: '[[ -n $value &&\n  -n $other ]]',
      close: {
        start: {
          offset: 28,
        },
      },
    });
  });

  test('算術コマンドは改行を含んで終端まで読む', () => {
    const result = parse('(( 1 +\n  2 ))\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(command).toMatchObject({
      kind: 'opaqueCommand',
      syntax: 'arithmetic',
      raw: '(( 1 +\n  2 ))',
      close: {
        start: {
          offset: 11,
        },
      },
    });
  });

  test('条件コマンドの終端がない場合は専用diagnosticを返す', () => {
    const result = parse('[[ -n $value\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics.map((diagnostic) => diagnostic.kind)).toEqual([
      'missingConditionEnd',
    ]);
    expect(command).toMatchObject({
      kind: 'opaqueCommand',
      syntax: 'condition',
      close: null,
    });
  });

});
