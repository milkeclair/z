import { describe, expect, test } from 'vitest';
import { findAll } from '../../src/zshParser/ast';
import { createZshFileHydration } from '../../src/zshHydrator';
import { createClassState, classDeclaration, classCommands } from '../../src/diagnostics/classes';

function command(content: string) {
  const file = createZshFileHydration({ sourceFile: 'classes.zsh', file: 'classes.zsh', content });
  const node = findAll(file.ast, 'simpleCommand')[0];
  if (!node) throw new Error('Expected a command in the class fixture');
  return node;
}

describe('createClassState', () => {
  test('空の独立した状態を返す', () => {
    const first = createClassState();
    const second = createClassState();
    expect(first.definitions.size).toBe(0);
    expect(first.instances.size).toBe(0);
    expect(first.pending).toBeNull();
    expect(first.definitions).not.toBe(second.definitions);
    expect(first.instances).not.toBe(second.instances);
  });
});

describe('classDeclaration', () => {
  test('入力を変更せずに定義を開始する', () => {
    const before = createClassState();
    const next = classDeclaration(command('z.cls.draw Counter'), 1, undefined, before);
    expect(before.pending).toBeNull();
    expect(next.pending).toMatchObject({ kind: 'definition', definition: { name: 'Counter' } });
    expect(next.definitions.size).toBe(0);
  });

  test('属性のget/setを追加し、前のメンバー集合を保持する', () => {
    const drawing = classDeclaration(command('z.cls.draw Counter'), 1, undefined, createClassState());
    const next = classDeclaration(command('z.cls.attr count 0'), 1, undefined, drawing);
    expect(drawing.pending?.definition.members.size).toBe(0);
    expect([...next.pending?.definition.members ?? []]).toEqual(['count.get', 'count.set']);
  });

  test('同じ深さの終了マーカーで本体を閉じ、公開時だけ定義に加える', () => {
    const drawing = classDeclaration(command('z.cls.draw Counter'), 1, undefined, createClassState());
    const method = classDeclaration(command('z.cls.fn increment'), 1, undefined, drawing);
    expect(method.pending?.kind).toBe('method');
    expect(classDeclaration(command('z.cls.fn.done'), 2, undefined, method)).toBe(method);
    const ended = classDeclaration(command('z.cls.fn.done'), 1, undefined, method);
    expect(ended.pending?.kind).toBe('definition');
    expect(method.pending?.kind).toBe('method');
    const published = classDeclaration(command('z.cls.drew'), 1, undefined, ended);
    expect([...published.definitions.get('Counter') ?? []]).toEqual(['increment']);
    expect(published.pending).toBeNull();
    expect(ended.definitions.size).toBe(0);
  });

  test('inline本体は捕捉状態に入らず登録する', () => {
    const drawing = classDeclaration(command('z.cls.draw Counter'), 1, undefined, createClassState());
    const next = classDeclaration(command("z.cls.fn value 'REPLY=$count'"), 1, undefined, drawing);
    expect(next.pending?.kind).toBe('definition');
    expect([...next.pending?.definition.members ?? []]).toEqual(['value']);
  });

  test('入れ子の別関数にある終了名では本体を閉じない', () => {
    const file = createZshFileHydration({ sourceFile: 'scope.zsh', file: 'scope.zsh', content: 'helper() { : }' });
    const scope = file.functions[0]?.definition;
    if (!scope) throw new Error('Expected a function scope');
    const drawing = classDeclaration(command('z.cls.draw Counter'), 1, undefined, createClassState());
    const method = classDeclaration(command('z.cls.fn run'), 1, undefined, drawing);
    expect(classDeclaration(command('z.cls.fn.done'), 1, scope, method)).toBe(method);
  });

  test('同名bindingの候補を入力集合を変えずに追加する', () => {
    const first = classDeclaration(command('z.cls.new Counter object'), 1, undefined, createClassState());
    const next = classDeclaration(command('z.cls.new ArrayBox object'), 1, undefined, first);
    expect([...first.instances.get('object') ?? []]).toEqual(['Counter']);
    expect([...next.instances.get('object') ?? []]).toEqual(['Counter', 'ArrayBox']);
  });

  test.each(['z.cls.new $class object', 'z.cls.new z_cls_reserved object', 'z.cls.new Counter bad-name',
    'z.cls.new Counter', 'z.cls.draw bad-name'])('不完全・動的・予約済みの宣言を登録しない: %s', source => {
    const before = createClassState();
    expect(classDeclaration(command(source), 1, undefined, before)).toBe(before);
  });

  test('abortで未公開の定義を破棄し、入力状態を保持する', () => {
    const drawing = classDeclaration(command('z.cls.draw Counter'), 1, undefined, createClassState());
    const next = classDeclaration(command('z.cls.abort'), 1, undefined, drawing);
    expect(next.pending).toBeNull();
    expect(drawing.pending?.definition.name).toBe('Counter');
    expect(next.definitions.size).toBe(0);
  });
});

describe('classCommands', () => {
  test('別ファイルの定義と複数の候補を組み合わせ、入力集合を保持する', () => {
    const definitions = new Map([['Counter', new Set(['increment', 'count.get'])], ['ArrayBox', new Set(['fill'])]]);
    const instances = new Map([['object', new Set(['Counter', 'ArrayBox'])]]);
    const result = classCommands([{ definitions, instances: new Map() }, { definitions: new Map(), instances }]);
    expect([...result]).toEqual(['object.increment', 'object.count.get', 'object.fill']);
    expect(definitions.size).toBe(2);
    expect(instances.get('object')?.size).toBe(2);
  });

  test('未公開クラスからはコマンドを生成しない', () => {
    expect([...classCommands([{ definitions: new Map(), instances: new Map([['object', new Set(['Missing'])]]) }])]).toEqual([]);
  });
});
