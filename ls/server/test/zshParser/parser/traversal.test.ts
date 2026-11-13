import { describe, expect, test } from 'vitest';
import type { AstNode, CommandNode, FileNode, GroupCommandNode } from '../../../src/zshParser/ast';
import { walk, findAll, locate, createQueryContext, mapAst } from '../../../src/zshParser/ast';
import { parse, commandFromItem } from './helper';

describe('ast@traversal', () => {
  test('heredocのrangeが重なる後続コマンドを検索する', () => {
    const source = 'cat <<EOF; [[ -n x ]]\nbody\nEOF\n';
    const query = createQueryContext(parse(source).ast);
    expect(locate(query, source.indexOf('-n'))).toMatchObject({ kind: 'syntax', node: { kind: 'opaqueCommand' } });
  });

  test('複数heredocの演算子とそれぞれの終端の所有者を検索する', () => {
    const source = 'cat <<A <<B\none\nA\ntwo\nB\n';
    const file = parse(source).ast;
    const redirects = findAll(file, 'redirect');
    const query = createQueryContext(file);
    expect(locate(query, source.indexOf('<<B'))?.node).toBe(redirects[1]);
    expect(locate(query, source.indexOf('\nA\n') + 1)?.node).toBe(redirects[0]);
    expect(locate(query, source.indexOf('\nB\n') + 1)?.node).toBe(redirects[1]);
  });

  test('構文と関連参照を区別し、共有ノードを一回だけ訪問する', () => {
    const file = parse('source config.zsh\n# docs\nhelper() { print "$name" }\n').ast;
    const syntax: AstNode[] = []; const related: AstNode[] = [];
    walk(file, (node) => { syntax.push(node); });
    walk(file, (node) => { related.push(node); }, { includeRelated: true });
    expect(syntax.filter((node) => node.kind === 'comment')).toEqual([]);
    expect(related.filter((node) => node.kind === 'word' && node.raw === 'config.zsh')).toHaveLength(1);
    const definition = findAll(file, 'functionDefinition')[0];
    expect(definition.leadingDoc?.comments[0]).toBe(file.comments[0]);
    expect(related.filter((node) => node === file.comments[0])).toHaveLength(1);
  });

  test('leading doc、構文の最深ノード、EOFを検索する', () => {
    const source = '# docs\nhelper() { print "$name" }\n';
    const file = parse(source).ast; const query = createQueryContext(file);
    expect(locate(query, 2)).toMatchObject({ kind: 'comment', node: file.comments[0], target: findAll(file, 'functionDefinition')[0] });
    const location = locate(query, source.indexOf('name') + 1);
    expect(location).toMatchObject({ kind: 'syntax', node: { kind: 'variableName', value: 'name' } });
    if (location?.kind !== 'syntax') throw new Error('syntax location required');
    expect(location.path[0]).toBe(file);
    expect(location.path.at(-1)).toBe(location.node);
    expect(locate(query, source.length)).toMatchObject({ kind: 'syntax', node: file.eof });
    expect(locate(query, -1)).toBeNull();
    expect(locate(query, source.length + 1)).toBeNull();
  });

  test('skipとstopで探索範囲を制御する', () => {
    const file = parse('helper() { print inner }\nprint outer\n').ast;
    const values: string[] = [];
    walk(file, (node) => {
      if (node.kind === 'functionDefinition') return 'skip';
      if (node.kind === 'word') values.push(node.raw);
    });
    expect(values).toEqual(['print', 'outer']);
    let visited = 0;
    walk(file, () => { visited += 1; return 'stop'; });
    expect(visited).toBe(1);
  });

  test('変換は元ASTを保持し、semanticの共有参照も更新する', () => {
    const original = parse('source config.zsh').ast;
    const transformed = mapAst(original, (node) => {
      if (node.kind === 'word' && node.raw === 'config.zsh') {
        const decorated = { ...node, testFlag: true };
        return decorated;
      }
      return node;
    });
    const command = commandFromItem(transformed.body.items[0]);
    const before = commandFromItem(original.body.items[0]);
    if (command.kind !== 'simpleCommand' || command.semantic.role !== 'source' || before.kind !== 'simpleCommand') throw new Error('source command required');
    expect(command.arguments[0]).toBe(command.semantic.source.target);
    expect(command.arguments[0]).not.toBe(before.arguments[0]);
    expect('testFlag' in before.arguments[0]).toBe(false);
    expect(mapAst(original, (node) => node)).toBe(original);
  });

  test('1万段のASTでwalk、map、位置検索をスタックに依存せず実行する', () => {
    const sample = parse('echo ok').ast;
    const first = sample.body.items[0];
    if (first.sublist.kind !== 'sublist') throw new Error('sublist required');
    let command: CommandNode = first.sublist.first.first;
    const range = command.range;
    for (let depth = 0; depth < 10000; depth += 1) {
      const group: GroupCommandNode = {
        kind: 'groupCommand', range, openBrace: range, closeBrace: range, always: null, postBodyRedirects: [],
        body: { kind: 'list', range, items: [{ kind: 'listItem', range, terminator: null,
          sublist: { kind: 'sublist', range, rest: [], first: { kind: 'pipeline', range, timing: null, modifier: null, rest: [], first: command } } }] },
      };
      command = group;
    }
    const file: FileNode = { ...sample, body: { ...sample.body, items: [{ ...first,
      sublist: { ...first.sublist, first: { ...first.sublist.first, first: command } } }] } };
    expect(findAll(file, 'groupCommand')).toHaveLength(10000);
    expect(mapAst(file, (node) => node)).toBe(file);
    const location = locate(createQueryContext(file), 1);
    if (location?.kind !== 'syntax') throw new Error('syntax location required');
    expect(location.path.length).toBeGreaterThan(50000);
  });
});
