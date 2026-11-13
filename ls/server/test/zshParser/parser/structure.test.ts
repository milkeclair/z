import { describe, expect, test } from 'vitest';
import { commandFromItem, parse, simpleCommandFromItem, TestSourceFile } from './helper';

describe('parse@structure', () => {
  test('空文字列はeofだけを持つfileを返す', () => {
    const result = parse('');

    expect(result.diagnostics).toEqual([]);
    expect(result.ast).toMatchObject({
      kind: 'file',
      path: TestSourceFile,
      body: {
        kind: 'list',
        items: [],
      },
      eof: {
        kind: 'eof',
      },
    });
    expect(result.tokens.map((token) => token.kind)).toEqual(['eof']);
  });

  test('改行で区切られたcommandをlistItemとして読む', () => {
    const result = parse('source somefile\nlocal somevar=$other\n');

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(2);
    expect(result.ast.body.items.map((item) => item.terminator?.type ?? null)).toEqual([
      'newline',
      'newline',
    ]);
    expect(simpleCommandFromItem(result.ast.body.items[0]).commandName?.value).toBe('source');
    expect(simpleCommandFromItem(result.ast.body.items[1]).commandName?.value).toBe('local');
  });

  test('groupとsubshellはcommandとして読む', () => {
    const result = parse('{ echo a }\n(echo b)\n');

    expect(result.diagnostics).toEqual([]);
    expect(commandFromItem(result.ast.body.items[0]).kind).toBe('groupCommand');
    expect(commandFromItem(result.ast.body.items[1]).kind).toBe('subshellCommand');
  });

  test('group後のredirectは同じgroupCommandに保持する', () => {
    const result = parse('{ echo a } > out\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(command).toMatchObject({
      kind: 'groupCommand',
      postBodyRedirects: [
        {
          operator: '>',
          target: {
            raw: 'out',
          },
        },
      ],
    });
  });

  test('subshell後のredirectは同じsubshellCommandに保持する', () => {
    const result = parse('(echo b) < in\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(command).toMatchObject({
      kind: 'subshellCommand',
      postBodyRedirects: [
        {
          operator: '<',
          target: {
            raw: 'in',
          },
        },
      ],
    });
  });

  test('subshell後のfd付きredirectは同じsubshellCommandに保持する', () => {
    const result = parse('(echo b) >/dev/null 2>&1\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(command).toMatchObject({
      kind: 'subshellCommand',
      postBodyRedirects: [
        {
          operator: '>',
          target: {
            raw: '/dev/null',
          },
        },
        {
          operator: '2>&',
          target: {
            raw: '1',
          },
        },
      ],
    });
  });

  test('groupのalways句は同じcommandに保持する', () => {
    const result = parse('{ echo try } always { echo always }\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(command).toMatchObject({
      kind: 'groupCommand',
      always: {
        kind: 'alwaysClause',
        body: {
          kind: 'groupCommand',
          body: {
            items: [
              {
                sublist: {
                  first: {
                    first: {
                      kind: 'simpleCommand',
                      commandName: {
                        value: 'echo',
                      },
                    },
                  },
                },
              },
            ],
          },
        },
      },
    });
  });

  test('logicalOperator直後の閉じbraceはgroupのcloseBraceとして残す', () => {
    const result = parse('{ foo && }\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics.map((diagnostic) => diagnostic.kind)).toEqual([
      'unknownCommand',
    ]);
    expect(command).toMatchObject({
      kind: 'groupCommand',
      closeBrace: {
        start: {
          offset: 9,
        },
      },
    });
  });
});
