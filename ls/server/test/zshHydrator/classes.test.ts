import { describe, expect, test } from 'vitest';
import { findAll, mapAst } from '../../src/zshParser/ast';
import { Lexer } from '../../src/zshParser/lexer';
import { Parser } from '../../src/zshParser/parser';
import { createZshFileHydration, hydrateAst } from '../../src/zshHydrator';
import { classInformationOf, classesFromAst, classMethodAt, hydrateClasses } from '../../src/zshHydrator/classes';
import { astContractViolations } from '../zshParser/parser/contracts';

const source = ['z.cls.draw Counter; {', '  z.cls.attr count 0', '  z.cls.fn increment',
  '    (( ++count ))', '    print "$1"', '  z.cls.fn.done', "  z.cls.fn value 'REPLY=$count'", '  z.cls.drew', '}',
  'z.cls.new Counter object', ''].join('\n');
function fixture(content = source) {
  return createZshFileHydration({ sourceFile: '/project/classes.zsh', file: 'classes.zsh', content });
}

describe('class hydration', () => {
  test('classのないASTは追加コピーせず返す', () => {
    const file = fixture('print hello\n');
    expect(hydrateClasses(file.ast)).toBe(file.ast);
  });

  test('深い構文内の終了名ではメソッドを閉じない', () => {
    const text = source.replace('(( ++count ))', 'if true; then z.cls.fn.done; fi\n    print deeper');
    const file = fixture(text);
    const method = file.classes.definitions[0].methods[0];
    expect(method.body.kind).toBe('block');
    if (method.body.kind !== 'block') throw new Error('Expected a block method');
    expect(method.body.end?.start.offset).toBe(text.lastIndexOf('z.cls.fn.done'));
    expect(classMethodAt(file.classes, null, text.indexOf('print deeper'))).toBe(method);
  });

  test.each(['z.cls.new $class object', 'z.cls.new z_cls_reserved object', 'z.cls.new Counter bad-name',
    'z.cls.new Counter', 'z.cls.draw bad-name'])('動的・不完全・予約済みの名前を決め打ちしない: %s', text => {
    const file = fixture(text + '\n');
    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('同名instanceのnative function scopeを返却ASTに結び付ける', () => {
    const file = fixture('z.cls.new Counter object\nload() { local object; z.cls.new Other object; }\n');
    expect(file.classes.instances[0].scope.kind).toBe('file');
    const local = file.classes.instances[1];
    expect(local.scope.kind).toBe('function');
    if (local.scope.kind !== 'function') throw new Error('Expected function ownership');
    expect(local.scope.declaration).toBe(file.functions[0].definition);
  });

  test('子のcommandを付加情報で更新してもdefaultのWord参照が古くならない', () => {
    const file = fixture('z.cls.draw Holder\nz.cls.attr value "$(z.cls.new Other inside)"\nz.cls.drew\n');
    const attribute = file.classes.definitions[0].attributes[0];
    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    const binding = file.classes.instances.find(item => item.name === 'inside');
    expect(binding).toBeDefined();
    expect(findAll(attribute.defaultValue, 'simpleCommand')).toContain(binding?.declaration);
    expect(file.classes.definitions[0].file).toBe(file.ast);
  });

  test('既存のclass付加情報が入力に残っていても現在の構文から更新する', () => {
    const information = classInformationOf(fixture().classes.definitions[0].declaration);
    if (!information) throw new Error('Expected class information');
    const ordinary = fixture('print hello\n');
    const stale = mapAst(ordinary.ast, node => node.kind === 'simpleCommand' ? { ...node, hydration: information } : node);
    const refreshed = hydrateAst(stale, 'print hello\n');
    expect(findAll(refreshed, 'simpleCommand').map(classInformationOf)).toEqual([null]);
    expect(classesFromAst(refreshed).definitions).toEqual([]);
    expect(findAll(stale, 'simpleCommand').map(classInformationOf)).toEqual([information]);
  });

  test('class・属性・メソッド・instanceに意味情報を付与し、通常の構文ノードを保持する', () => {
    const file = fixture();
    const definition = file.classes.definitions[0];
    expect(definition).toMatchObject({ kind: 'classDefinition', name: 'Counter', state: 'published' });
    expect(definition.declaration.kind).toBe('simpleCommand');
    expect(classInformationOf(definition.declaration)?.kind).toBe('classDefinition');
    expect(definition.attributes.map(item => item.name)).toEqual(['count']);
    expect(definition.methods.map(item => item.name)).toEqual(['increment', 'value']);
    expect(file.classes.instances[0]).toMatchObject({ kind: 'classInstance', className: 'Counter', name: 'object' });
    expect(astContractViolations(file.ast, file.tokens, source)).toEqual([]);
  });

  test('索引と属性値・名前が返却ASTと同じノードを参照する', () => {
    const file = fixture();
    const commands = findAll(file.ast, 'simpleCommand');
    const definition = file.classes.definitions[0];
    expect(commands).toContain(definition.declaration);
    expect(definition.nameNode).toBe(definition.declaration.arguments[0]);
    const attribute = definition.attributes[0];
    expect(commands).toContain(attribute.declaration);
    expect(attribute.nameNode).toBe(attribute.declaration.arguments[0]);
    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    expect(file.classes.instances[0].nameNode).toBe(file.classes.instances[0].declaration.arguments[1]);
    expect(classesFromAst(file.ast)).toEqual(file.classes);
  });

  test('blockとinlineの本体を元の範囲またはWordとして保持する', () => {
    const file = fixture();
    const [block, inline] = file.classes.definitions[0].methods;
    expect(block.body.kind).toBe('block');
    if (block.body.kind !== 'block') throw new Error('Expected a block method');
    expect(source.slice(block.body.range.start.offset, block.body.range.end.offset)).toContain('(( ++count ))');
    expect(source.slice(block.body.range.start.offset, block.body.range.end.offset)).not.toContain('z.cls.fn.done');
    expect(inline.body.kind).toBe('inline');
    if (inline.body.kind !== 'inline') throw new Error('Expected an inline method');
    expect(inline.body.value).toBe(inline.declaration.arguments[1]);
    expect(classMethodAt(file.classes, null, source.indexOf('print "$1"'))).toBe(block);
    expect(classMethodAt(file.classes, null, source.indexOf('z.cls.fn.done'))).toBeNull();
  });

  test('入力ASTを変更せず再hydrationしても意味情報を重複させない', () => {
    const parsed = Parser.parse(Lexer.tokenize(source, { sourceFile: 'x' }).tokens, { sourceFile: 'x', path: 'x' });
    const ast = hydrateAst(parsed.ast, source);
    expect(findAll(parsed.ast, 'simpleCommand').map(classInformationOf).filter(Boolean)).toEqual([]);
    expect(hydrateAst(ast, source)).toEqual(ast);
    expect(classesFromAst(ast).definitions).toHaveLength(1);
  });

  test('未完了とabortを公開済みclassと区別する', () => {
    const incomplete = fixture('z.cls.draw Open\nz.cls.fn run\nprint "$1"\n');
    expect(incomplete.classes.definitions[0]).toMatchObject({ name: 'Open', state: 'incomplete' });
    expect(incomplete.classes.definitions[0].methods[0].body).toMatchObject({ kind: 'block', end: null });
    const aborted = fixture('z.cls.draw Discarded\nz.cls.attr count 0\nz.cls.abort\n');
    expect(aborted.classes.definitions[0]).toMatchObject({ name: 'Discarded', state: 'aborted' });
  });

  test('文字列・コメント・非function呼出をclassと誤認しない', () => {
    const file = fixture('# z.cls.draw Comment\nprint "z.cls.draw String"\ncommand z.cls.draw External\nbuiltin z.cls.new Counter object\n');
    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('native関数ごとのclassを独立して解釈し、本体内の引数スコープを保持する', () => {
    const text = 'load() {\n' + source.slice(0, source.indexOf('z.cls.new')) + '}\n';
    const file = fixture(text);
    const owner = file.functions.find(fn => fn.name === 'load')?.definition;
    expect(file.classes.definitions[0].scope).toBe(owner);
    expect(owner && classMethodAt(file.classes, owner, text.indexOf('print "$1"'))?.name).toBe('increment');
    expect(classMethodAt(file.classes, null, text.indexOf('print "$1"'))).toBeNull();
  });

  test('入れ子のnative関数にある終端名で外側のメソッドを閉じない', () => {
    const file = fixture(source.replace('(( ++count ))', 'helper() { z.cls.fn.done }\n    print "z.cls.fn.done"'));
    expect(file.classes.definitions[0].methods.map(m => m.name)).toEqual(['increment', 'value']);
  });

  test('メソッド内のinstance宣言をclass method scopeに結び付ける', () => {
    const file = fixture(source.replace('(( ++count ))', 'z.cls.new Other nested'));
    const binding = file.classes.instances.find(i => i.name === 'nested');
    expect(binding?.scope.kind).toBe('classMethod');
    if (binding?.scope.kind !== 'classMethod') throw new Error('Expected a method scope');
    expect(binding.scope.declaration).toBe(file.classes.definitions[0].methods[0].declaration);
  });

  test('native関数内のclassと外側のclassを同じpending状態にしない', () => {
    const text = 'z.cls.draw Outer\nhelper() { z.cls.draw Inner; z.cls.drew }\nz.cls.drew\n';
    const file = fixture(text);
    expect(file.classes.definitions.map(d => d.name)).toEqual(['Outer', 'Inner']);
    expect(file.classes.definitions.find(d => d.name === 'Inner')?.scope).toBe(file.functions[0].definition);
  });
});
