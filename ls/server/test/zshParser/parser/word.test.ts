import { describe, expect, test } from 'vitest';
import { findAll } from '../../../src/zshParser/ast';
import type { WordPartNode } from '../../../src/zshParser/ast';
import { tokensInRange } from '../../../src/zshParser/parser';
import { parse, simpleCommandFromItem, sublistFromItem } from './helper';

describe('parse@word', () => {
  test('wordは変数参照をpartとして持つ', () => {
    const command = simpleCommandFromItem(parse('echo somevar=$other\n').ast.body.items[0]);
    const word = command.arguments[0];

    expect(word).toMatchObject({
      kind: 'word',
      raw: 'somevar=$other',
      parts: [
        {
          kind: 'stringLiteral',
          value: 'somevar=',
        },
        {
          kind: 'variableReference',
          name: {
            value: 'other',
          },
        },
      ],
    });
    expect(word?.parts.map((part) => part.range)).toEqual([
      {
        start: { offset: 5, line: 0, character: 5 },
        end: { offset: 13, line: 0, character: 13 },
      },
      {
        start: { offset: 13, line: 0, character: 13 },
        end: { offset: 19, line: 0, character: 19 },
      },
    ]);
  });

  test('assignは同じword tokenからnameとvalueを分解する', () => {
    const command = simpleCommandFromItem(parse('local somevar=$other\n').ast.body.items[0]);

    expect(command.semantic).toMatchObject({
      role: 'declaration',
      declaration: {
        assignments: [
          {
            name: {
              value: 'somevar',
              range: {
                start: { offset: 6, line: 0, character: 6 },
                end: { offset: 13, line: 0, character: 13 },
              },
            },
            value: {
              range: {
                start: { offset: 14, line: 0, character: 14 },
                end: { offset: 20, line: 0, character: 20 },
              },
              value: {
                raw: '$other',
                parts: [
                  {
                    kind: 'variableReference',
                    name: {
                      value: 'other',
                    },
                  },
                ],
              },
            },
          },
        ],
      },
    });
  });

  test('nodeのrangeから元のword tokenを逆引きできる', () => {
    const result = parse('local somevar=$other\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    if (command.semantic.role !== 'declaration') {
      throw new Error('declarationではありません');
    }

    const assignment = command.semantic.declaration.assignments[0];

    expect(tokensInRange(result.tokens, assignment.name.range).map((token) => token.value)).toEqual([
      'somevar=$other',
    ]);
    expect(tokensInRange(result.tokens, assignment.value?.range ?? assignment.range).map((token) => token.value)).toEqual([
      'somevar=$other',
    ]);
  });

  test('複数tokenの展開構文を1つのwordとして読む', () => {
    const command = simpleCommandFromItem(parse('echo ${foo} $(bar) $((1+2)) a${foo}b\n').ast.body.items[0]);

    expect(command.arguments.map((argument) => ({
      raw: argument.raw,
      parts: argument.parts.map((part) => part.kind),
    }))).toEqual([
      {
        raw: '${foo}',
        parts: ['parameterExpansion'],
      },
      {
        raw: '$(bar)',
        parts: ['commandSubstitution'],
      },
      {
        raw: '$((1+2))',
        parts: ['arithmeticExpansion'],
      },
      {
        raw: 'a${foo}b',
        parts: ['stringLiteral', 'parameterExpansion', 'stringLiteral'],
      },
    ]);
  });

  test('single quoteとbackslashでquotedされた$は変数参照にしない', () => {
    const command = simpleCommandFromItem(parse('echo \'$foo\' \\$bar "$baz"\n').ast.body.items[0]);

    expect(command.arguments.map((argument) => ({
      raw: argument.raw,
      parts: argument.parts.map((part) => part.kind),
    }))).toEqual([
      {
        raw: '\'$foo\'',
        parts: ['stringLiteral'],
      },
      {
        raw: '\\$bar',
        parts: ['stringLiteral'],
      },
      {
        raw: '"$baz"',
        parts: ['stringLiteral', 'variableReference', 'stringLiteral'],
      },
    ]);
  });

  test('位置パラメータと特殊パラメータは展開partとして読む', () => {
    const command = simpleCommandFromItem(parse('echo function_name=$1 "$@" $? $! $$ $# $#args\n').ast.body.items[0]);

    expect(command.arguments.map((argument) => ({
      raw: argument.raw,
      parts: argument.parts.map((part) => part.kind),
    }))).toEqual([
      {
        raw: 'function_name=$1',
        parts: ['stringLiteral', 'parameterExpansion'],
      },
      {
        raw: '"$@"',
        parts: ['stringLiteral', 'parameterExpansion', 'stringLiteral'],
      },
      {
        raw: '$?',
        parts: ['parameterExpansion'],
      },
      {
        raw: '$!',
        parts: ['parameterExpansion'],
      },
      {
        raw: '$$',
        parts: ['parameterExpansion'],
      },
      {
        raw: '$#',
        parts: ['parameterExpansion'],
      },
      {
        raw: '$#args',
        parts: ['parameterExpansion'],
      },
    ]);
  });

  test('配列内の位置パラメータと特殊パラメータもraw全体を表す', () => {
    const command = simpleCommandFromItem(parse('local args=($@) pids=($!)\n').ast.body.items[0]);

    expect(command.arguments.map((argument) => ({
      raw: argument.raw,
      partsRaw: partsRaw(argument.parts),
    }))).toEqual([
      {
        raw: 'args=($@)',
        partsRaw: 'args=($@)',
      },
      {
        raw: 'pids=($!)',
        partsRaw: 'pids=($!)',
      },
    ]);
  });

  test('配列代入は括弧内を含めてassignとして読む', () => {
    const result = parse('local arr=($REPLY) empty=() name+=(a b)\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command.semantic).toMatchObject({
      role: 'declaration',
      declaration: {
        assignments: [
          {
            name: { value: 'arr' },
            operator: '=',
            value: {
              value: {
                raw: '($REPLY)',
              },
            },
          },
          {
            name: { value: 'empty' },
            operator: '=',
            value: {
              value: {
                raw: '()',
              },
            },
          },
          {
            name: { value: 'name' },
            operator: '+=',
            value: {
              value: {
                raw: '(a b)',
              },
            },
          },
        ],
      },
    });
  });

  test('配列代入のword partsは括弧と区切り空白を含めてraw全体を表す', () => {
    const result = parse('local words=( ${=str} ) result=($log $failed $compact)\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    if (command.semantic.role !== 'declaration') {
      throw new Error('declarationではありません');
    }

    const [words, resultAssignment] = command.semantic.declaration.assignments;

    expect(command.arguments[0].raw).toBe('words=( ${=str} )');
    expect(partsRaw(command.arguments[0].parts)).toBe('words=( ${=str} )');
    expect(command.arguments[1].raw).toBe('result=($log $failed $compact)');
    expect(partsRaw(command.arguments[1].parts)).toBe('result=($log $failed $compact)');
    expect(words.value?.value.raw).toBe('( ${=str} )');
    expect(partsRaw(words.value?.value.parts ?? [])).toBe('( ${=str} )');
    expect(resultAssignment.value?.value.raw).toBe('($log $failed $compact)');
    expect(partsRaw(resultAssignment.value?.value.parts ?? [])).toBe('($log $failed $compact)');
  });

  test('prefixの配列代入はcommandNameの前に保持する', () => {
    const result = parse('args=($@) echo ok\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command.prefixAssignments).toMatchObject([
      {
        name: { value: 'args' },
        value: {
          value: {
            raw: '($@)',
          },
        },
      },
    ]);
    expect(command.commandName?.value).toBe('echo');
  });

  test('添字付き代入はprefixAssignmentとして読む', () => {
    const result = parse('hash[name]="John"\nz_completion_docs[z.example]=$\'docs\' # zls: ignore\n');
    const first = simpleCommandFromItem(result.ast.body.items[0]);
    const second = simpleCommandFromItem(result.ast.body.items[1]);

    expect(result.diagnostics).toEqual([]);
    expect(first.commandName).toBeNull();
    expect(first.prefixAssignments).toMatchObject([
      {
        name: { value: 'hash' },
        subscript: { raw: 'name' },
        operator: '=',
        value: {
          value: {
            raw: '"John"',
          },
        },
      },
    ]);
    expect(second.commandName).toBeNull();
    expect(second.prefixAssignments).toMatchObject([
      {
        name: { value: 'z_completion_docs' },
        subscript: { raw: 'z.example' },
        operator: '=',
        value: {
          value: {
            raw: '$\'docs\'',
          },
        },
      },
    ]);
  });

  test('fd付きredirectはargumentにしない', () => {
    const command = simpleCommandFromItem(parse('echo ok 2>&1\n').ast.body.items[0]);

    expect(command.arguments.map((argument) => argument.raw)).toEqual(['ok']);
    expect(command.redirects).toMatchObject([
      {
        operator: '2>&',
        target: {
          raw: '1',
        },
      },
    ]);
  });

  test('配列代入内のcommentはsource textとしてrawに保持する', () => {
    const result = parse('local order=(\n  var # var are used in fn\n  fn\n)\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);
    const assignment = command.semantic.role === 'declaration'
      ? command.semantic.declaration.assignments[0]
      : null;

    expect(result.ast.comments.map((comment) => comment.text)).toEqual(['# var are used in fn']);
    expect(command.arguments[0].raw).toBe('order=(\n  var # var are used in fn\n  fn\n)');
    expect(partsRaw(command.arguments[0].parts)).toBe('order=(\n  var # var are used in fn\n  fn\n)');
    expect(assignment?.value?.value.raw).toBe('(\n  var # var are used in fn\n  fn\n)');
    expect(partsRaw(assignment?.value?.value.parts ?? [])).toBe('(\n  var # var are used in fn\n  fn\n)');
  });

  test('ネストしたparameter expansionは1つのwordとして読む', () => {
    const result = parse('export z_root=${Z_ROOT:-${${(%):-%N}:A:h}}\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command.semantic).toMatchObject({
      role: 'declaration',
      declaration: {
        assignments: [
          {
            name: { value: 'z_root' },
            value: {
              value: {
                raw: '${Z_ROOT:-${${(%):-%N}:A:h}}',
                parts: [
                  {
                    kind: 'parameterExpansion',
                    raw: '${Z_ROOT:-${${(%):-%N}:A:h}}',
                  },
                ],
              },
            },
          },
        ],
      },
    });
  });

  test('parameter expansion内の#はcommentにせずwordとして読む', () => {
    const result = parse('local line_count=${#lines[@]}\nstr=${str##[[:space:]]##}\n');
    const firstCommand = simpleCommandFromItem(result.ast.body.items[0]);
    const secondCommand = simpleCommandFromItem(result.ast.body.items[1]);

    expect(result.diagnostics).toEqual([]);
    expect(firstCommand.semantic).toMatchObject({
      role: 'declaration',
      declaration: {
        assignments: [
          {
            name: { value: 'line_count' },
            value: {
              value: {
                raw: '${#lines[@]}',
              },
            },
          },
        ],
      },
    });
    expect(secondCommand.prefixAssignments).toMatchObject([
      {
        name: { value: 'str' },
        value: {
          value: {
            raw: '${str##[[:space:]]##}',
          },
        },
      },
    ]);
  });

  test('parameter expansion内の#は後続のlogical operatorを飲み込まない', () => {
    const result = parse('z.int.is.zero ${#function_names[@]} && return 1\n');
    const sublist = sublistFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(result.ast.body.items).toHaveLength(1);
    expect(sublist.rest).toHaveLength(1);
    expect(simpleCommandFromItem(result.ast.body.items[0]).arguments).toMatchObject([
      {
        raw: '${#function_names[@]}',
        parts: [
          {
            kind: 'parameterExpansion',
            raw: '${#function_names[@]}',
          },
        ],
      },
    ]);
    expect(sublist.rest[0]?.operator.type).toBe('andIf');
    expect(sublist.rest[0]?.pipeline.first).toMatchObject({
      kind: 'simpleCommand',
      commandName: {
        value: 'return',
      },
      arguments: [
        {
          raw: '1',
        },
      ],
    });
  });

  test('ネストしたcommand substitutionは1つのwordとして読む', () => {
    const result = parse('z.t.expect.reply $(dirname $(pwd))\n');
    const command = simpleCommandFromItem(result.ast.body.items[0]);

    expect(result.diagnostics).toEqual([]);
    expect(command.arguments).toMatchObject([
      {
        raw: '$(dirname $(pwd))',
        parts: [
          {
            kind: 'commandSubstitution',
            raw: '$(dirname $(pwd))',
          },
        ],
      },
    ]);
  });

  test.each([
    { word: String.raw`pre'$a'"$b"`, names: ['b'] },
    { word: String.raw`"a\$literal $real"`, names: ['real'] },
    { word: String.raw`a\ b$var`, names: ['var'] },
    { word: String.raw`"a\"$real"`, names: ['real'] },
    { word: String.raw`"\\$real"`, names: ['real'] },
    { word: String.raw`"\q$real"`, names: ['real'] },
    { word: String.raw`$'it\'s $literal'"$real"`, names: ['real'] },
  ])('引用状態とescapeに従って$wordの変数参照を読む', ({ word, names }) => {
    const result = parse(`echo ${word}\n`);
    const argument = simpleCommandFromItem(result.ast.body.items[0]).arguments[0];

    expect(result.diagnostics).toEqual([]);
    expect(argument.raw).toBe(word);
    expect(argument.parts.flatMap((part) =>
      part.kind === 'variableReference' ? [part.name.value] : [],
    )).toEqual(names);
    expect(partsRaw(argument.parts)).toBe(word);
    expect(argument.parts.map((part) => word.slice(
      part.range.start.offset - 5,
      part.range.end.offset - 5,
    )).join('')).toBe(word);
  });
});

function partsRaw(parts: readonly WordPartNode[]): string {
  return parts.map(partRaw).join('');
}

function partRaw(part: WordPartNode): string {
  if (part.kind === 'stringLiteral') {
    return part.value;
  } else if (part.kind === 'variableReference') {
    return `${part.sigil}${part.name.value}`;
  } else {
    return part.raw;
  }
}

describe('parse@lexicalWordGroups', () => {
  test.each([
    'items=(case x in)',
    'items=(one # ) comment\n two)',
    'for file in *(#qN); do print "$file"; done',
    '[[ ABC == (#i)abc ]]',
  ])('wordとcommandの括弧contextを区別する: %s', (source) => {
    expect(parse(source).diagnostics).toEqual([]);
  });
});

describe('parse@arrayComments', () => {
  test('comment内の展開や引用符をwordの構造へ混ぜない', () => {
    const source = "items=(one # '$fake\n $real)\n";
    const result = parse(source);
    expect(result.diagnostics).toEqual([]);
    expect(findAll(result.ast, 'variableReference').map((node) => node.name.value)).toEqual(['real']);
    expect(result.ast.comments.map((node) => node.text)).toEqual(["# '$fake"]);
  });
});
