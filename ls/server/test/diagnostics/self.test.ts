import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { analyzeCalls } from '../../src/diagnostics/calls';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { emptyShellEnvironment } from '../../src/diagnostics/environment';
import { findAll } from '../../src/zshParser/ast';

const roots: string[] = [];
afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});

const classApi = [
  'z.cls.draw() { : }',
  '# $1: attribute name',
  '# $default: initial value',
  'z.cls.attr() { : "$@" }',
  '# $1: method name',
  '# $2? [code]: inline body',
  '# $access?: method access',
  'z.cls.method() { : "$@" }',
  'z.cls.method.defined() { : }',
  'z.cls.drew() { : }',
  'z.cls.new() { : }',
  '# $1 [code]: body',
  'run_code() { eval "$1" }',
  '',
].join('\n');

const counter = [
  'z.cls.draw Counter',
  '  z.cls.attr count default=0',
  '  z.cls.attr self default=business',
  '  z.cls.method increment',
  '    "$self.count.get"',
  '    "$self.count.set" 1',
  '  z.cls.method.defined',
  '  z.cls.method twice',
  '    "$self.increment"',
  '  z.cls.method.defined',
  '  z.cls.drew',
  '',
].join('\n');

function fixture(source = counter) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-self-diag-'));
  roots.push(root);
  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'class.zsh')).href,
    'shellscript',
    1,
    classApi + source,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: emptyShellEnvironment() });
  const report = diagnostics.files.get(document.uri);
  if (!report) throw new Error('Expected class diagnostics');
  const analysis = analyzeCalls(snapshot, report.file, report.facts.calls, diagnostics.context);
  return { snapshot, diagnostics, document, report, analysis };
}

describe('selfのクラス参照', () => {
  test('所有メソッドのクラスからメソッドと属性を実際の宣言へ解決する', () => {
    const scenario = fixture();
    const targets = [...scenario.analysis.classTargets.values()].flat();
    const definition = scenario.report.file.classes.definitions[0];

    expect(targets.map((target) => target.operation)).toEqual(['get', 'set', 'method']);
    expect(targets.map((target) => target.member.name)).toEqual(['count', 'count', 'increment']);
    expect(targets.every((target) => target.definition === definition)).toBe(true);
    expect(targets.every((target) => target.instance === null)).toBe(true);
    expect(targets[0].member).toBe(definition.attributes[0]);
    expect(targets[2].member).toBe(definition.methods[0]);
  });

  test('既知のselfのメンバーのタイプミスを元の位置へ診断する', () => {
    const scenario = fixture(counter.replace('"$self.increment"', '"$self.typo"'));
    const items = scenario.report.items.filter((item) => item.code === 'undefined-command');
    const offset = scenario.document.getText().indexOf('"$self.typo"');

    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({
      message: '$self.typo is not defined in class Counter.',
      range: { start: scenario.document.positionAt(offset) },
    });
  });
  test('引用しないselfと波括弧で囲んだselfも同じ所有クラスへ解決する', () => {
    const scenario = fixture(
      counter.replace(
        '"$self.increment"',
        '$self.increment\n    ${self}.count.get\n    "${self}.count.set" 2',
      ),
    );
    const targets = [...scenario.analysis.classTargets.values()].flat();

    expect(targets.map((target) => target.operation)).toEqual([
      'get',
      'set',
      'method',
      'get',
      'set',
    ]);
    expect(
      targets.every((target) => target.definition === scenario.report.file.classes.definitions[0]),
    ).toBe(true);
  });

  test('selfという属性名を実体参照のselfと区別する', () => {
    const scenario = fixture(counter.replace('"$self.increment"', '"$self.self.get"'));
    const targets = [...scenario.analysis.classTargets.values()].flat();
    const definition = scenario.report.file.classes.definitions[0];

    expect(targets[2].operation).toBe('get');
    expect(targets[2].member).toBe(definition.attributes[1]);
    expect(targets[2].member.name).toBe('self');
    expect(targets[2].instance).toBeNull();
  });

  test('メソッド外のself参照をクラスへ結び付けない', () => {
    const scenario = fixture(counter + '"$self.typo"\n');
    const targets = [...scenario.analysis.classTargets.keys()];

    expect(targets).toHaveLength(3);
    expect(targets.some((command) => command.commandName?.word.raw === '"$self.typo"')).toBe(false);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });

  test('入れ子の通常の関数で宣言したselfを外側のクラスへ結び付けない', () => {
    const scenario = fixture(
      counter.replace(
        '"$self.increment"',
        'helper() {\n      local self=other\n      "$self.typo"\n    }\n    "$self.increment"',
      ),
    );

    expect([...scenario.analysis.classTargets.values()].flat()).toHaveLength(3);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });

  test('selfを明示的に宣言しない通常の関数でも所属を推測しない', () => {
    const scenario = fixture(
      counter.replace('"$self.increment"', 'helper() { "$self.typo" }\n    "$self.increment"'),
    );

    expect([...scenario.analysis.classTargets.values()].flat()).toHaveLength(3);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });

  test('匿名関数で新しいselfを宣言したスコープへ外側の所属を持ち込まない', () => {
    const scenario = fixture(
      counter.replace(
        '"$self.increment"',
        '() {\n      local self=other\n      "$self.typo"\n    }\n    "$self.increment"',
      ),
    );

    expect(
      findAll(scenario.report.file.ast, 'simpleCommand').some(
        (command) =>
          command.semantic.role === 'declaration' &&
          command.semantic.declaration.kind === 'local' &&
          command.semantic.declaration.assignments.some(
            (assignment) => assignment.name.value === 'self',
          ),
      ),
    ).toBe(true);
    expect([...scenario.analysis.classTargets.values()].flat()).toHaveLength(3);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });

  test('通常の関数内で定義したクラスのメソッドへselfを結び付ける', () => {
    const scenario = fixture(
      [
        'load() {',
        '  z.cls.draw LocalCounter',
        '    z.cls.attr count default=0',
        '    z.cls.method value',
        '      "$self.count.get"',
        '    z.cls.method.defined',
        '    z.cls.drew',
        '}',
        '',
      ].join('\n'),
    );
    const target = [...scenario.analysis.classTargets.values()].flat()[0];
    const definition = scenario.report.file.classes.definitions[0];
    const owner = scenario.report.file.functions.find((fn) => fn.name === 'load');

    expect(target.definition).toBe(definition);
    expect(definition.scope).toBe(owner?.definition);
    expect(target.member).toBe(definition.attributes[0]);
  });

  test('別のクラスに同名メソッドがあっても実際の所有クラスだけを使う', () => {
    const scenario = fixture(
      counter +
        [
          'z.cls.draw Other',
          '  z.cls.attr label default=other',
          '  z.cls.method twice',
          '    "$self.label.get"',
          '    "$self.count.get"',
          '  z.cls.method.defined',
          '  z.cls.drew',
          '',
        ].join('\n'),
    );
    const targets = [...scenario.analysis.classTargets.values()].flat();
    const other = scenario.report.file.classes.definitions[1];

    expect(targets[3].definition).toBe(other);
    expect(targets[3].member).toBe(other.attributes[0]);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toMatchObject(
      [{ message: '$self.count.get is not defined in class Other.' }],
    );
  });

  test('引数で渡す本体のselfを元のメソッドとクラスへ結び付ける', () => {
    const scenario = fixture(
      [
        'z.cls.draw Inline',
        '  z.cls.attr count default=0',
        '  z.cls.method value \'"$self.count.get"\'',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );
    const program = scenario.report.codePrograms[0];
    if (!program) throw new Error('Expected an inline code program');

    const analysis = analyzeCalls(
      scenario.snapshot,
      program.file,
      findAll(program.file.ast, 'simpleCommand'),
      scenario.diagnostics.context,
      { scopes: [{ file: scenario.report.file, offset: program.word.range.start.offset }] },
    );
    const target = [...analysis.classTargets.values()].flat()[0];
    const definition = scenario.report.file.classes.definitions[0];
    const method = definition.methods[0];

    expect(method.body.kind).toBe('inline');
    if (method.body.kind !== 'inline') throw new Error('Expected an inline method');

    expect(program.word).toBe(method.body.value);
    expect(program.root).toBe(scenario.report.file);
    expect(target.definition).toBe(definition);
    expect(target.member).toBe(definition.attributes[0]);
    expect(target.operation).toBe('get');
    expect(target.instance).toBeNull();
  });

  test('引数形式の本体のselfの診断を元の引用内へ対応付ける', () => {
    const scenario = fixture(
      ['z.cls.draw Inline', '  z.cls.method value \'"$self.typo"\'', '  z.cls.drew', ''].join('\n'),
    );
    const items = scenario.report.items.filter((item) => item.code === 'undefined-command');
    const offset = scenario.document.getText().indexOf('"$self.typo"');

    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({
      message: '$self.typo is not defined in class Inline.',
      range: { start: scenario.document.positionAt(offset) },
    });
  });

  test('入れ子のコード引数でも既知のselfと平坦化した元位置を保持する', () => {
    const scenario = fixture(
      [
        'z.cls.draw InlineNested',
        '  z.cls.method value \'run_code "\\$self.typo"\'',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );
    const items = scenario.report.items.filter((item) => item.code === 'undefined-command');
    const offset = scenario.document.getText().indexOf('\\$self.typo');

    expect(scenario.report.codePrograms).toHaveLength(2);
    expect(items).toHaveLength(1);
    expect(items[0]).toMatchObject({
      message: '$self.typo is not defined in class InlineNested.',
      range: { start: scenario.document.positionAt(offset) },
    });
  });

  test('コード引数内の通常の関数を越えてselfを推測しない', () => {
    const scenario = fixture(
      [
        'z.cls.draw InlineHelper',
        '  z.cls.method value \'helper() { "$self.typo" }; helper\'',
        '  z.cls.drew',
        '',
      ].join('\n'),
    );

    expect(scenario.report.codePrograms).toHaveLength(1);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });

  test('変動する実体やメンバー名を静的なself呼出しと扱わない', () => {
    const scenario = fixture(
      counter.replace(
        '"$self.increment"',
        '"$self.$member"\n    "$other.increment"\n    prefix$self.increment\n    "${self:-other}.increment"',
      ),
    );

    expect([...scenario.analysis.classTargets.values()].flat()).toHaveLength(2);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });

  test('selfの診断にも既存の制御コメントを適用する', () => {
    const scenario = fixture(
      counter.replace('"$self.increment"', '"$self.typo" # zls: ignore undefined-command'),
    );

    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });
  test('コード引数で宣言したselfを外側のメソッドへ結び付けない', () => {
    const scenario = fixture(
      counter.replace('"$self.increment"', 'run_code \'local self=other; "$self.typo"\''),
    );

    expect(scenario.report.codePrograms).toHaveLength(1);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });
  test('新しいスコープのtypesetによるself宣言も外側へ結び付けない', () => {
    const scenario = fixture(
      counter.replace(
        '"$self.increment"',
        '() {\n      typeset self=other\n      "$self.typo"\n    }\n    "$self.increment"',
      ),
    );

    expect([...scenario.analysis.classTargets.values()].flat()).toHaveLength(3);
    expect(scenario.report.items.filter((item) => item.code === 'undefined-command')).toEqual([]);
  });
  test('読み取り専用selfからの更新とwriteメソッドを報告する', () => {
    const source = counter.replace(
      '  z.cls.drew',
      [
        '  # $self [Counter<read>]: 読み取る実体',
        '  z.cls.method bad',
        '    $self.count.set 2',
        '    $self.increment',
        '  z.cls.method.defined',
        '  # $self [Counter<read>]: 読み取る実体',
        "  z.cls.method using_read '$self.count.get'",
        '  z.cls.drew',
      ].join('\n'),
    );
    const scenario = fixture(source);

    expect(
      scenario.report.items.filter((item) => item.code === 'class-readonly-write'),
    ).toHaveLength(2);
    expect(
      scenario.report.file.classes.definitions[0]?.methods.map(({ name, access }) => [
        name,
        access,
      ]),
    ).toContainEqual(['using_read', 'read']);
  });
  test('readメソッドのselfをwriteが必要な関数へ渡すと報告する', () => {
    const source = [
      '# $1 [Counter<write>]: 更新する実体',
      'update() { $1.count.set 1; }',
      counter.replace(
        '  z.cls.drew',
        '  # $self [Counter<read>]: 読み取る実体\n  z.cls.method bad\n    update "$self"\n  z.cls.method.defined\n  z.cls.drew',
      ),
    ].join('\n');
    const scenario = fixture(source);
    expect(
      scenario.report.items.filter((item) => item.code === 'class-argument-type'),
    ).toHaveLength(1);
  });
});
