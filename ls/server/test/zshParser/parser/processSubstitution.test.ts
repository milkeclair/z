import { describe, expect, test } from 'vitest';
import { findAll } from '../../../src/zshParser/ast';
import { parse, simpleCommandFromItem } from './helper';

describe('Parser.parse', () => {
  describe('プロセス置換を解析する場合', () => {
    test('空白の後のファイル置換を配列要素として保持する', () => {
      const gap = ' ';

      const source = 'items=(' + gap + '=(cat <<EOF\n) literal\nEOF\n))\n';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'hereDocument')[0]?.raw).toBe(') literal\n');
    });

    test('タブの後のファイル置換を配列要素として保持する', () => {
      const gap = '\t';

      const source = 'items=(' + gap + '=(cat <<EOF\n) literal\nEOF\n))\n';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'hereDocument')[0]?.raw).toBe(') literal\n');
    });

    test('改行の後のファイル置換を配列要素として保持する', () => {
      const gap = '\n';

      const source = 'items=(' + gap + '=(cat <<EOF\n) literal\nEOF\n))\n';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'hereDocument')[0]?.raw).toBe(') literal\n');
    });

    test('forの列挙値をプロセス置換として読む', () => {
      const source = 'for item in <(print x); do :; done';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'processSubstitution')[0].body?.items).toHaveLength(1);
    });

    test('selectの列挙値をプロセス置換として読む', () => {
      const source = 'select item in <(print x); do :; done';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'processSubstitution')[0].body?.items).toHaveLength(1);
    });

    test('foreachの列挙値をプロセス置換として読む', () => {
      const source = 'foreach item (<(print x))\n:\nend';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'processSubstitution')[0].body?.items).toHaveLength(1);
    });

    test('caseの比較対象をプロセス置換として読む', () => {
      const source = 'case <(print x) in *) :;; esac';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'processSubstitution')[0].body?.items).toHaveLength(1);
    });

    test('repeatの回数をプロセス置換として読む', () => {
      const source = 'repeat <(print x) do :; done';

      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(findAll(result.ast, 'processSubstitution')).toHaveLength(1);
      expect(findAll(result.ast, 'processSubstitution')[0].body?.items).toHaveLength(1);
    });

    test('配列中の置換にも独立したcommandの字句状態を持つ', () => {
      const source = 'items=(<(cat <<EOF\n) literal # $fake\nEOF\n))\n# after\n';
      const result = parse(source);

      expect(result.diagnostics).toEqual([]);
      expect(result.ast.comments.map((node) => node.text)).toEqual(['# after']);
      expect(findAll(result.ast, 'hereDocument')[0].raw).toBe(') literal # $fake\n');
    });

    test('入力プロセス置換の本体を保持する', () => {
      const raw = '<(print x)';
      const direction = 'input';

      const result = parse('cat ' + raw);

      expect(result.diagnostics).toEqual([]);
      const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];

      expect(argument).toMatchObject({
        raw,
        parts: [
          {
            kind: 'processSubstitution',
            raw,
            direction,
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { kind: 'simpleCommand', commandName: { value: 'print' } } },
                  },
                },
              ],
            },
          },
        ],
      });
    });

    test('出力プロセス置換の本体を保持する', () => {
      const raw = '>(print x)';
      const direction = 'output';

      const result = parse('cat ' + raw);

      expect(result.diagnostics).toEqual([]);
      const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];

      expect(argument).toMatchObject({
        raw,
        parts: [
          {
            kind: 'processSubstitution',
            raw,
            direction,
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { kind: 'simpleCommand', commandName: { value: 'print' } } },
                  },
                },
              ],
            },
          },
        ],
      });
    });

    test('ファイル置換の本体を保持する', () => {
      const raw = '=(print x)';
      const direction = 'file';

      const result = parse('cat ' + raw);

      expect(result.diagnostics).toEqual([]);
      const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];

      expect(argument).toMatchObject({
        raw,
        parts: [
          {
            kind: 'processSubstitution',
            raw,
            direction,
            body: {
              items: [
                {
                  sublist: {
                    first: { first: { kind: 'simpleCommand', commandName: { value: 'print' } } },
                  },
                },
              ],
            },
          },
        ],
      });
    });
  });
});
