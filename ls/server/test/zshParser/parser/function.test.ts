import { describe, expect, test } from 'vitest';
import { commandFromItem, parse } from './helper';

describe('parse@function', () => {
  test('sh互換の関数定義はFunctionDefinitionNodeになる', () => {
    const command = commandFromItem(parse('foo() { echo hi }\n').ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      form: 'shCompatible',
      names: [
        {
          raw: 'foo',
        },
      ],
      openParen: {
        start: {
          offset: 3,
        },
        end: {
          offset: 4,
        },
      },
      closeParen: {
        start: {
          offset: 4,
        },
        end: {
          offset: 5,
        },
      },
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
    });
  });

  test('function形式はoptionと複数nameを保持する', () => {
    const command = commandFromItem(parse('function -T foo bar () { echo hi }\n').ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      form: 'functionKeyword',
      options: [
        {
          name: '-T',
        },
      ],
      names: [
        {
          raw: 'foo',
        },
        {
          raw: 'bar',
        },
      ],
    });
  });

  test('関数定義のbodyはcommandも持てる', () => {
    const command = commandFromItem(parse('foo() echo hi\n').ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      body: {
        kind: 'simpleCommand',
        commandName: {
          value: 'echo',
        },
      },
    });
  });

  test('関数body内の空配列代入は関数定義として誤検出しない', () => {
    const result = parse('foo() {\n  values=()\n}\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command).toMatchObject({
      kind: 'functionDefinition',
      body: {
        kind: 'groupCommand',
        body: {
          items: [
            {
              sublist: {
                first: {
                  first: {
                    kind: 'simpleCommand',
                    prefixAssignments: [
                      {
                        name: { value: 'values' },
                        value: {
                          value: {
                            raw: '()',
                          },
                        },
                      },
                    ],
                    commandName: null,
                  },
                },
              },
            },
          ],
        },
      },
    });
  });

  test('関数定義後のredirectはpostBodyRedirectsに入る', () => {
    const command = commandFromItem(parse('foo() { echo hi } > out\n').ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
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

  test('改行後のredirectは関数定義のpostBodyRedirectsに入れない', () => {
    const result = parse('foo() { echo hi }\n> out\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      postBodyRedirects: [],
    });
    expect(result.ast.body.items).toHaveLength(2);
  });

  test('関数定義後のinline commentはfunctionDefinitionのrangeに含めない', () => {
    const source = 'foo() { echo hi } # zls: ignore\n';
    const result = parse(source);
    const command = commandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.comments.map((comment) => comment.text)).toEqual(['# zls: ignore']);
    expect(command).toMatchObject({
      kind: 'functionDefinition',
      range: {
        end: {
          offset: 'foo() { echo hi }'.length,
        },
      },
      leadingDoc: null,
    });
  });

  test('関数直前の連続commentはDocBlockとして接続する', () => {
    const command = commandFromItem(parse('# one\n# two\nfoo() { echo hi }\n').ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      leadingDoc: {
        kind: 'docBlock',
        comments: [
          {
            text: '# one',
          },
          {
            text: '# two',
          },
        ],
      },
    });
  });

  test('空行を挟んだcommentはDocBlockにしない', () => {
    const command = commandFromItem(parse('# one\n\nfoo() { echo hi }\n').ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      leadingDoc: null,
    });
  });

  test('bodyがない関数定義はdiagnosticsを返す', () => {
    const result = parse('foo()\n');
    const command = commandFromItem(result.ast.body.items[0]);

    expect(command).toMatchObject({
      kind: 'functionDefinition',
      body: {
        kind: 'unknown',
        reason: 'missingFunctionBody',
      },
    });
    expect(result.diagnostics).toMatchObject([
      {
        kind: 'missingFunctionBody',
      },
    ]);
  });
});
