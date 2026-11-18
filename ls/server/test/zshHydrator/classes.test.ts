import { describe, expect, test } from 'vitest';
import { findAll, mapAst } from '../../src/zshParser/ast';
import { Lexer } from '../../src/zshParser/lexer';
import { Parser } from '../../src/zshParser/parser';
import { createZshFileHydration, hydrateAst } from '../../src/zshHydrator';
import {
  classInformationOf,
  classesFromAst,
  classMethodAt,
  hydrateClasses,
} from '../../src/zshHydrator/classes';
import { astContractViolations } from '../zshParser/parser/contracts';

const source = [
  'z.cls.draw Counter',
  '  z.cls.attr count default=0',
  '  z.cls.fn increment',
  '    (( ++count ))',
  '    print "$1"',
  '  z.cls.fn.done',
  "  z.cls.fn value 'REPLY=$count'",
  '  z.cls.drew',
  'z.cls.new Counter object',
  '',
].join('\n');

function fixture(content = source) {
  return createZshFileHydration({
    sourceFile: '/project/classes.zsh',
    file: 'classes.zsh',
    content,
  });
}

describe('class hydration', () => {
  test('重複した本体収集形式のメソッドはクラスを破棄する', () => {
    const file = fixture(
      [
        'z.cls.draw Duplicate',
        "  z.cls.fn run ':'",
        '  z.cls.fn run',
        '  z.cls.fn.done',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(file.classes.definitions[0].state).toBe('aborted');
    expect(file.classes.definitions[0].methods).toHaveLength(1);
  });

  test('重複した引数形式のメソッドは元の本体を保持する', () => {
    const file = fixture(
      [
        'z.cls.draw Duplicate',
        "  z.cls.fn run 'print first'",
        "  z.cls.fn run 'print second'",
        '  z.cls.drew',
        '',
      ].join('\n'),
    );
    const definition = file.classes.definitions[0];
    const method = definition.methods[0];

    expect(definition.state).toBe('published');
    expect(definition.methods).toHaveLength(1);
    expect(method.body.kind).toBe('inline');
    if (method.body.kind !== 'inline') throw new Error('Expected an inline method');

    expect(method.body.value.raw).toBe("'print first'");
  });

  test('重複した属性は元の初期値を保持しクラスを破棄する', () => {
    const file = fixture(
      [
        'z.cls.draw Duplicate',
        '  z.cls.attr value default=first',
        '  z.cls.attr value default=second',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );
    const definition = file.classes.definitions[0];

    expect(definition.state).toBe('aborted');
    expect(definition.attributes).toHaveLength(1);
    expect(definition.attributes[0].defaultValue.raw).toBe('default=first');
  });

  test('索引の再構築が既存索引を変更せず返却ASTの参照を保持する', () => {
    const file = fixture();
    const original = file.classes;
    const rebuilt = classesFromAst(file.ast);

    expect(rebuilt).toEqual(original);
    expect(rebuilt.definitions).not.toBe(original.definitions);
    expect(rebuilt.definitions[0].attributes).not.toBe(original.definitions[0].attributes);
    expect(rebuilt.definitions[0].attributes[0].defaultValue).toBe(
      original.definitions[0].attributes[0].defaultValue,
    );
    expect(rebuilt.instances[0].declaration).toBe(original.instances[0].declaration);
  });

  test('実行時と同じ予約接頭辞だけを除外する', () => {
    const file = fixture(
      ['z.cls.draw __z_cls_Box', '  z.cls.attr __z_cls_value default=0', '  z.cls.drew', ''].join(
        '\n',
      ),
    );

    expect(file.classes.definitions[0].name).toBe('__z_cls_Box');
    expect(file.classes.definitions[0].attributes[0].name).toBe('__z_cls_value');
  });

  test('クラスのないASTは追加コピーせず返す', () => {
    const file = fixture('print hello\n');

    expect(hydrateClasses(file.ast)).toBe(file.ast);
  });

  test('深い構文内の終了名ではメソッドを閉じない', () => {
    const text = source.replace(
      '(( ++count ))',
      'if true; then z.cls.fn.done; fi\n    print deeper',
    );
    const file = fixture(text);
    const method = file.classes.definitions[0].methods[0];

    expect(method.body.kind).toBe('block');
    if (method.body.kind !== 'block') throw new Error('Expected a block method');

    expect(method.body.end?.start.offset).toBe(text.lastIndexOf('z.cls.fn.done'));
    expect(classMethodAt(file.classes, null, text.indexOf('print deeper'))).toBe(method);
  });

  test('変数で指定したクラス名を決め打ちしない', () => {
    const file = fixture('z.cls.new $class object\n');

    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('予約済みのクラス名を登録しない', () => {
    const file = fixture('z.cls.new z_cls_reserved object\n');

    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('不正な実体名を登録しない', () => {
    const file = fixture('z.cls.new Counter bad-name\n');

    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('実体名のない宣言を登録しない', () => {
    const file = fixture('z.cls.new Counter\n');

    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('不正なクラス名で定義を開始しない', () => {
    const file = fixture('z.cls.draw bad-name\n');

    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('同名の実体の関数スコープを返却ASTに結び付ける', () => {
    const file = fixture(
      'z.cls.new Counter object\nload() { local object=""; z.cls.new Other object; }\n',
    );

    expect(file.classes.instances[0].scope.kind).toBe('file');
    const binding = file.classes.instances[1];

    expect(binding.scope.kind).toBe('function');
    if (binding.scope.kind !== 'function') throw new Error('Expected function ownership');

    expect(binding.scope.declaration).toBe(file.functions[0].definition);
  });

  test('子のコマンドに情報を付加しても初期値のWord参照が古くならない', () => {
    const file = fixture(
      [
        'z.cls.draw Holder',
        '  z.cls.attr value default="$(z.cls.new Other inside)"',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    const binding = file.classes.instances.find((item) => item.name === 'inside');

    expect(binding).toBeDefined();
    expect(findAll(attribute.defaultValue, 'simpleCommand')).toContain(binding?.declaration);
    expect(file.classes.definitions[0].file).toBe(file.ast);
  });

  test('既存のクラス付加情報が入力に残っていても現在の構文から更新する', () => {
    const information = classInformationOf(fixture().classes.definitions[0].declaration);
    if (!information) throw new Error('Expected class information');
    const ordinary = fixture('print hello\n');
    const stale = mapAst(ordinary.ast, (node) =>
      node.kind === 'simpleCommand' ? { ...node, hydration: information } : node,
    );
    const refreshed = hydrateAst(stale, 'print hello\n');

    expect(findAll(refreshed, 'simpleCommand').map(classInformationOf)).toEqual([null]);
    expect(classesFromAst(refreshed).definitions).toEqual([]);
    expect(findAll(stale, 'simpleCommand').map(classInformationOf)).toEqual([information]);
  });

  test('クラス・属性・メソッド・実体に意味情報を付与し、通常の構文ノードを保持する', () => {
    const file = fixture();
    const definition = file.classes.definitions[0];

    expect(definition).toMatchObject({
      kind: 'classDefinition',
      name: 'Counter',
      state: 'published',
    });
    expect(definition.declaration.kind).toBe('simpleCommand');
    expect(classInformationOf(definition.declaration)?.kind).toBe('classDefinition');
    expect(definition.attributes.map((item) => item.name)).toEqual(['count']);
    expect(definition.methods.map((item) => item.name)).toEqual(['increment', 'value']);
    expect(file.classes.instances[0]).toMatchObject({
      kind: 'classInstance',
      className: 'Counter',
      name: 'object',
    });
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
    expect(file.classes.instances[0].nameNode).toBe(
      file.classes.instances[0].declaration.arguments[1],
    );
    expect(classesFromAst(file.ast)).toEqual(file.classes);
  });

  test('本体を元の範囲または引数のWordとして保持する', () => {
    const file = fixture();
    const [block, inline] = file.classes.definitions[0].methods;

    expect(block.body.kind).toBe('block');
    if (block.body.kind !== 'block') throw new Error('Expected a block method');

    expect(source.slice(block.body.range.start.offset, block.body.range.end.offset)).toContain(
      '(( ++count ))',
    );
    expect(source.slice(block.body.range.start.offset, block.body.range.end.offset)).not.toContain(
      'z.cls.fn.done',
    );
    expect(inline.body.kind).toBe('inline');
    if (inline.body.kind !== 'inline') throw new Error('Expected an inline method');

    expect(inline.body.value).toBe(inline.declaration.arguments[1]);
    expect(classMethodAt(file.classes, null, source.indexOf('print "$1"'))).toBe(block);
    expect(classMethodAt(file.classes, null, source.indexOf('z.cls.fn.done'))).toBeNull();
  });

  test('入力ASTへ情報を付加し直しても意味情報を重複させない', () => {
    const parsed = Parser.parse(Lexer.tokenize(source, { sourceFile: 'x' }).tokens, {
      sourceFile: 'x',
      path: 'x',
    });
    const ast = hydrateAst(parsed.ast, source);

    expect(findAll(parsed.ast, 'simpleCommand').map(classInformationOf).filter(Boolean)).toEqual(
      [],
    );
    expect(hydrateAst(ast, source)).toEqual(ast);
    expect(classesFromAst(ast).definitions).toHaveLength(1);
  });

  test('未完了と破棄済みのクラスを公開済みのクラスと区別する', () => {
    const incomplete = fixture(
      ['z.cls.draw Open', '  z.cls.fn run', '    print "$1"', ''].join('\n'),
    );

    expect(incomplete.classes.definitions[0]).toMatchObject({ name: 'Open', state: 'incomplete' });
    expect(incomplete.classes.definitions[0].methods[0].body).toMatchObject({
      kind: 'block',
      end: null,
    });
    const aborted = fixture(
      ['z.cls.draw Discarded', '  z.cls.attr count default=0', '  z.cls.abort', ''].join('\n'),
    );

    expect(aborted.classes.definitions[0]).toMatchObject({ name: 'Discarded', state: 'aborted' });
  });

  test('文字列・コメント・関数以外の呼出しをクラスと誤認しない', () => {
    const file = fixture(
      '# z.cls.draw Comment\nprint "z.cls.draw String"\ncommand z.cls.draw External\nbuiltin z.cls.new Counter object\n',
    );

    expect(file.classes.definitions).toEqual([]);
    expect(file.classes.instances).toEqual([]);
  });

  test('通常の関数ごとのクラスを独立して解釈し、本体内の引数スコープを保持する', () => {
    const text = [
      'load() {',
      '  z.cls.draw Counter',
      '    z.cls.attr count default=0',
      '    z.cls.fn increment',
      '      (( ++count ))',
      '      print "$1"',
      '    z.cls.fn.done',
      "    z.cls.fn value 'REPLY=$count'",
      '    z.cls.drew',
      '}',
      '',
    ].join('\n');
    const file = fixture(text);
    const owner = file.functions.find((fn) => fn.name === 'load')?.definition;

    expect(file.classes.definitions[0].scope).toBe(owner);
    expect(owner && classMethodAt(file.classes, owner, text.indexOf('print "$1"'))?.name).toBe(
      'increment',
    );
    expect(classMethodAt(file.classes, null, text.indexOf('print "$1"'))).toBeNull();
  });

  test('入れ子の関数にある終端名で外側のメソッドを閉じない', () => {
    const file = fixture(
      source.replace('(( ++count ))', 'helper() { z.cls.fn.done }\n    print "z.cls.fn.done"'),
    );

    expect(file.classes.definitions[0].methods.map((method) => method.name)).toEqual([
      'increment',
      'value',
    ]);
  });

  test('メソッド内の実体宣言をクラスメソッドのスコープに結び付ける', () => {
    const file = fixture(source.replace('(( ++count ))', 'z.cls.new Other nested'));
    const binding = file.classes.instances.find((instance) => instance.name === 'nested');

    expect(binding?.scope.kind).toBe('classMethod');
    if (binding?.scope.kind !== 'classMethod') throw new Error('Expected a method scope');

    expect(binding.scope.declaration).toBe(file.classes.definitions[0].methods[0].declaration);
  });

  test('関数内のクラスと外側のクラスを同じ定義中の状態にしない', () => {
    const text = [
      'z.cls.draw Outer',
      '  helper() {',
      '    z.cls.draw Inner',
      '      z.cls.drew',
      '  }',
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);

    expect(file.classes.definitions.map((definition) => definition.name)).toEqual([
      'Outer',
      'Inner',
    ]);
    expect(file.classes.definitions.find((definition) => definition.name === 'Inner')?.scope).toBe(
      file.functions[0].definition,
    );
  });
  test('defaultという属性名と名前付き初期値を区別する', () => {
    const text = [
      'z.cls.draw BusinessValue',
      '  z.cls.attr default default=0',
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.name).toBe('default');
    expect(attribute.nameNode).toBe(attribute.declaration.arguments[0]);
    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    expect(
      text.slice(attribute.defaultValueRange.start.offset, attribute.defaultValueRange.end.offset),
    ).toBe('0');
  });

  test('先に指定したdefault引数も元の単語へ結び付ける', () => {
    const file = fixture(
      ['z.cls.draw Reversed', '  z.cls.attr default=0 price', '  z.cls.drew', ''].join('\n'),
    );
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.name).toBe('price');
    expect(attribute.nameNode).toBe(attribute.declaration.arguments[1]);
    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[0]);
    expect(attribute.defaultValueRange.start.offset).toBe(
      attribute.defaultValue.range.start.offset + 'default='.length,
    );
  });

  test('明示した空のdefault値を長さ0の範囲で保持する', () => {
    const file = fixture(
      ['z.cls.draw EmptyDefault', '  z.cls.attr value default=', '  z.cls.drew', ''].join('\n'),
    );
    const attribute = file.classes.definitions[0].attributes[0];

    expect(file.classes.definitions[0].state).toBe('published');
    expect(attribute.defaultValue.raw).toBe('default=');
    expect(attribute.defaultValueRange).toEqual({
      start: attribute.defaultValue.range.end,
      end: attribute.defaultValue.range.end,
    });
  });

  test('引用した空のdefault値も長さ0の範囲で保持する', () => {
    const file = fixture(
      ['z.cls.draw QuotedEmpty', '  z.cls.attr value default=""', '  z.cls.drew', ''].join('\n'),
    );
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    expect(attribute.defaultValueRange).toEqual({
      start: attribute.defaultValue.range.end,
      end: attribute.defaultValue.range.end,
    });
  });

  test('引用した日本語の初期値を元ソースの値の位置へ結び付ける', () => {
    const text = [
      'z.cls.draw QuotedDefault',
      '  z.cls.attr label default="日本語の値"',
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    expect(attribute.defaultValueRange.start).toEqual({
      offset: text.indexOf('日本語の値'),
      line: 1,
      character: '  z.cls.attr label default="'.length,
    });
    expect(
      text.slice(attribute.defaultValueRange.start.offset, attribute.defaultValueRange.end.offset),
    ).toBe('日本語の値');
  });

  test('引用内に名前付き引数を記述しても値の範囲を保持する', () => {
    const text = [
      'z.cls.draw QuotedArgument',
      "  z.cls.attr value 'default=two words'",
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    expect(
      text.slice(attribute.defaultValueRange.start.offset, attribute.defaultValueRange.end.offset),
    ).toBe('two words');
  });

  test('展開を含むdefault値の構文と値の位置を保持する', () => {
    const text = [
      'z.cls.draw DynamicDefault',
      '  z.cls.attr value default="$(print text)"',
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);
    const attribute = file.classes.definitions[0].attributes[0];

    expect(attribute.defaultValue).toBe(attribute.declaration.arguments[1]);
    expect(findAll(attribute.defaultValue, 'commandSubstitution')).toHaveLength(1);
    expect(
      text.slice(attribute.defaultValueRange.start.offset, attribute.defaultValueRange.end.offset),
    ).toBe('$(print text)');
  });

  test('defaultを省略した属性があるクラスを公開しない', () => {
    const file = fixture(
      ['z.cls.draw MissingDefault', '  z.cls.attr price', '  z.cls.drew', ''].join('\n'),
    );

    expect(file.classes.definitions[0].state).toBe('aborted');
    expect(file.classes.definitions[0].attributes).toEqual([]);
  });

  test('位置引数の初期値を名前付きdefaultとして扱わない', () => {
    const file = fixture(
      ['z.cls.draw PositionalDefault', '  z.cls.attr price 0', '  z.cls.drew', ''].join('\n'),
    );

    expect(file.classes.definitions[0].state).toBe('aborted');
    expect(file.classes.definitions[0].attributes).toEqual([]);
  });

  test('defaultを重複指定したクラスを公開しない', () => {
    const file = fixture(
      [
        'z.cls.draw DuplicateDefault',
        '  z.cls.attr price default=0 default=1',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(file.classes.definitions[0].state).toBe('aborted');
    expect(file.classes.definitions[0].attributes).toEqual([]);
  });

  test('拒否した入れ子のクラスのメンバーと終端を外側へ混ぜない', () => {
    const file = fixture(
      [
        'z.cls.draw Outer',
        '  z.cls.attr kept default=0',
        '  z.cls.draw Inner',
        '    z.cls.attr leaked default=1',
        '    z.cls.drew',
        '  z.cls.attr tail default=2',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(file.classes.definitions.map((definition) => definition.name)).toEqual(['Outer']);
    expect(file.classes.definitions[0].state).toBe('published');
    expect(file.classes.definitions[0].attributes.map((attribute) => attribute.name)).toEqual([
      'kept',
      'tail',
    ]);
  });

  test('拒否した定義のメソッド内のマーカーで外側を閉じない', () => {
    const file = fixture(
      [
        'z.cls.draw Outer',
        '  z.cls.draw Rejected',
        '    z.cls.fn run',
        '      z.cls.draw Business',
        '      z.cls.drew',
        '      z.cls.abort',
        '    z.cls.fn.done',
        '    z.cls.abort',
        '    z.cls.drew',
        '  z.cls.attr kept default=0',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(file.classes.definitions.map((definition) => definition.name)).toEqual(['Outer']);
    expect(file.classes.definitions[0].state).toBe('published');
    expect(file.classes.definitions[0].attributes.map((attribute) => attribute.name)).toEqual([
      'kept',
    ]);
  });

  test('拒否した定義内の関数と置換のクラスを外へ混ぜない', () => {
    const file = fixture(
      [
        'z.cls.draw Outer',
        '  z.cls.draw Rejected',
        '    helper() { z.cls.draw Hidden; z.cls.drew }',
        '    z.cls.attr ignored default="$(z.cls.drew)"',
        '    z.cls.drew',
        '  z.cls.attr kept default=0',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(file.classes.definitions.map((definition) => definition.name)).toEqual(['Outer']);
    expect(file.classes.definitions[0].attributes.map((attribute) => attribute.name)).toEqual([
      'kept',
    ]);
    expect(file.functions.map((fn) => fn.name)).toContain('helper');
  });

  test('同じスコープで公開済みのクラス名を上書きしない', () => {
    const file = fixture(
      [
        'z.cls.draw Duplicate',
        '  z.cls.attr first default=0',
        '  z.cls.drew',
        'z.cls.draw Duplicate',
        '  z.cls.attr leaked default=1',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(file.classes.definitions).toHaveLength(1);
    expect(file.classes.definitions[0].attributes.map((attribute) => attribute.name)).toEqual([
      'first',
    ]);
  });

  test('メソッド本体のdrawとdrewを終了マーカーとして扱わない', () => {
    const text = [
      'z.cls.draw MethodMarkers',
      '  z.cls.fn run',
      '    z.cls.draw Business',
      '    z.cls.drew',
      '  z.cls.fn.done',
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);
    const method = file.classes.definitions[0].methods[0];

    expect(file.classes.definitions[0].state).toBe('published');
    expect(method.body.kind).toBe('block');
    if (method.body.kind !== 'block') throw new Error('Expected a block method');

    expect(text.slice(method.body.range.start.offset, method.body.range.end.offset)).toContain(
      'z.cls.drew',
    );
    expect(method.body.end?.start.offset).toBe(text.indexOf('z.cls.fn.done'));
  });

  test('論理演算・パイプ・非同期実行中のfn.doneでメソッドを閉じない', () => {
    const text = [
      'z.cls.draw MethodBoundary',
      '  z.cls.fn run',
      '    true && z.cls.fn.done',
      '    print value | z.cls.fn.done',
      '    z.cls.fn.done &',
      '    print tail',
      '  z.cls.fn.done',
      '  z.cls.drew',
      '',
    ].join('\n');
    const file = fixture(text);
    const method = file.classes.definitions[0].methods[0];

    expect(method.body.kind).toBe('block');
    if (method.body.kind !== 'block') throw new Error('Expected a block method');

    expect(method.body.end?.start.offset).toBe(text.lastIndexOf('z.cls.fn.done'));
    expect(classMethodAt(file.classes, null, text.indexOf('print tail'))).toBe(method);
  });

  test('通常のZshグループ内でもクラスを定義できる', () => {
    const file = fixture(
      ['z.cls.draw Grouped; {', '  z.cls.attr price default=0', '  z.cls.drew', '}', ''].join('\n'),
    );

    expect(file.classes.definitions[0].state).toBe('published');
    expect(file.classes.definitions[0].attributes.map((attribute) => attribute.name)).toEqual([
      'price',
    ]);
  });
});
