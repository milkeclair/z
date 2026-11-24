import { afterAll, afterEach, beforeAll, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { readShellEnvironment, emptyShellEnvironment } from '../../src/diagnostics/environment';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { validateTextDocument } from '../../src/diagnostics/main';
import { createZshFileHydration } from '../../src/zshHydrator';
import { sameClassFiles } from '../../src/diagnostics/classes';
import { analyzeCalls } from '../../src/diagnostics/calls';

const roots: string[] = [];
const environmentRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-class-diag-shell-'));
let environment: ShellEnvironment = emptyShellEnvironment();
beforeAll(async () => {
  fs.writeFileSync(path.join(environmentRoot, '.zshrc'), '');
  environment = await readShellEnvironment({ env: { ...process.env, ZDOTDIR: environmentRoot } });

  expect(environment.kind).toBe('available');
});
afterAll(() => fs.rmSync(environmentRoot, { recursive: true, force: true }));
afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
function fixture(content: string, definitions: string) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-class-diag-'));
  roots.push(root);

  const definitionUri = pathToFileURL(path.join(root, 'definition.zsh')).href;
  fs.writeFileSync(path.join(root, 'definition.zsh'), definitions);

  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    content,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment });

  return {
    root,
    snapshot,
    diagnostics,
    document,
    definitionUri,
    items: validateTextDocument({ diagnostics, textDocument: document }),
  };
}

const semantic = (items: Readonly<ReturnType<typeof validateTextDocument>>) =>
  items.filter((item) =>
    ['missing-positional-argument', 'missing-named-argument', 'undefined-command'].includes(
      item.code ?? '',
    ),
  );

const classApi =
  [
    'z.cls.draw() { : }',
    '# $1: attribute name',
    '# $default: initial value',
    'z.cls.attr() { : "$@" }',
    '# $1: method name',
    '# $2? [code]: inline body',
    'z.cls.fn() { : "$@" }',
    'z.cls.fn.done() { : }',
    'z.cls.drew() { : }',
    'z.cls.new() { : }',
  ].join('\n') + '\n';
const counterClass = [
  'z.cls.draw Counter',
  '  z.cls.attr count default=0',
  '  z.cls.fn increment',
  '    (( ++count ))',
  '  z.cls.fn.done',
  '  z.cls.drew',
  '',
].join('\n');

describe('class DSL command diagnostics', () => {
  test('引数形式のメソッド本体は共通のコード引数解析で元位置に診断する', () => {
    const source = counterClass.replace(
      'z.cls.fn increment\n    (( ++count ))\n  z.cls.fn.done',
      "z.cls.fn increment 'missing_inline_method'",
    );
    const scenario = fixture('', classApi + source);
    const diagnostics =
      scenario.diagnostics.files
        .get(scenario.definitionUri)
        ?.items.filter((item) => item.code === 'undefined-command') ?? [];

    expect(diagnostics).toHaveLength(1);
    expect(diagnostics[0].message).toContain('missing_inline_method');
    expect(diagnostics[0].range.start.line).toBe(12);
  });

  test('別ファイルのクラスから生成されるメソッドと属性を認識し、タイプミスは診断する', () => {
    const scenario = fixture(
      'z.cls.new Counter counter\n$counter.increment\n$counter.count.get\n$counter.count.set 3\n$counter.typo\n',
      classApi + counterClass,
    );

    expect(semantic(scenario.items)).toMatchObject([
      {
        code: 'undefined-command',
        message: '$counter.typo is not defined in class Counter.',
      },
    ]);

    expect(semantic(scenario.items)).toHaveLength(1);
  });

  test('メソッド内の未定義コマンドを元ファイルの位置で診断する', () => {
    const source = counterClass.replace('(( ++count ))', 'missing_inside_method');
    const scenario = fixture('', classApi + source);

    expect(
      semantic(scenario.diagnostics.files.get(scenario.definitionUri)?.items ?? []),
    ).toMatchObject([
      {
        code: 'undefined-command',
        range: { start: { line: 13, character: 4 } },
      },
    ]);
  });

  test('メソッドの編集で未編集の呼出元を再診断する', () => {
    const scenario = fixture(
      'z.cls.new Counter counter\n$counter.increment\n',
      classApi + counterClass,
    );

    expect(semantic(scenario.items)).toEqual([]);

    const changed = TextDocument.create(
      scenario.definitionUri,
      'shellscript',
      1,
      classApi + counterClass.replace('z.cls.fn increment', 'z.cls.fn reset'),
    );

    const snapshot = refreshFunctionSnapshot({
      projectRoot: scenario.root,
      documents: [scenario.document, changed],
      previous: scenario.snapshot,
    });
    const next = refreshDiagnosticSnapshot({
      snapshot,
      environment,
      previous: scenario.diagnostics,
    });

    expect(
      semantic(validateTextDocument({ diagnostics: next, textDocument: scenario.document })),
    ).toMatchObject([{ code: 'undefined-command' }]);
  });

  test('入れ子の関数や文字列内の終了名でメソッドを閉じない', () => {
    const source = counterClass.replace(
      '(( ++count ))',
      'helper() { z.cls.fn.done }\n    print "z.cls.fn.done"\n    z.cls.fn imaginary',
    );
    const scenario = fixture(
      'z.cls.new Counter counter\n$counter.increment\n$counter.imaginary\n',
      classApi + source,
    );

    expect(semantic(scenario.items)).toHaveLength(1);
    expect(semantic(scenario.items)[0]?.message).toContain('counter.imaginary');
  });
});

describe('scoped class references', () => {
  test('スコープによって異なるクラスを指す同名変数の呼出を認識する', () => {
    const arrayClass = [
      'z.cls.draw ArrayBox',
      '  z.cls.fn fill',
      '    :',
      '  z.cls.fn.done',
      '  z.cls.drew',
      '',
    ].join('\n');
    const source = [
      'z.cls.new Counter counter',
      '$counter.increment',
      'inner() {',
      '  local counter=""',
      '  z.cls.new ArrayBox counter',
      '  $counter.fill',
      '  $counter.increment',
      '}',
      '$counter.count.get',
      '$counter.fill',
      '',
    ].join('\n');

    const scenario = fixture(source, classApi + counterClass + arrayClass);

    expect(semantic(scenario.items).map((item) => item.message)).toEqual([
      '$counter.increment is not defined in class ArrayBox.',
      '$counter.fill is not defined in class Counter.',
    ]);
  });

  test('プロジェクト外の文書はプロジェクトと文書内のクラスを使い、文書内の定義は外へ漏れない', () => {
    const scenario = fixture('z.cls.new Local leaked\n$leaked.value\n', classApi + counterClass);
    const outside = TextDocument.create(
      pathToFileURL(path.join(path.dirname(scenario.root), 'outside.zsh')).href,
      'shellscript',
      1,
      [
        'z.cls.draw Local',
        '  z.cls.fn value "REPLY=1"',
        '  z.cls.drew',
        'z.cls.new Counter counter',
        '$counter.increment',
        'z.cls.new Local local_object',
        '$local_object.value',
        '$counter.value',
        '$local_object.increment',
        '',
      ].join('\n'),
    );
    const snapshot = refreshFunctionSnapshot({
      projectRoot: scenario.root,
      documents: [scenario.document, outside],
      previous: scenario.snapshot,
    });

    const diagnostics = refreshDiagnosticSnapshot({
      snapshot,
      environment,
      previous: scenario.diagnostics,
    });

    expect(diagnostics.files.get(outside.uri)?.project).toBe(false);
    expect(
      semantic(validateTextDocument({ diagnostics, textDocument: outside })).map(
        (item) => item.message,
      ),
    ).toEqual([
      '$counter.value is not defined in class Counter.',
      '$local_object.increment is not defined in class Local.',
    ]);

    const report = diagnostics.files.get(scenario.document.uri);
    if (!report) throw new Error('Expected caller diagnostics');
    const analysis = analyzeCalls(snapshot, report.file, report.facts.calls, diagnostics.context);

    expect(semantic(report.items)).toEqual([]);
    expect(analysis.classTargets.size).toBe(0);
  });

  test('外側の関数の引数使用へメソッド内の引数を混ぜない', () => {
    const source = [
      '# $1: loader argument',
      'load() {',
      '  z.cls.draw Counter',
      '    z.cls.attr count default=0',
      '    z.cls.fn increment',
      '      print "$1"',
      '    z.cls.fn.done',
      '    z.cls.drew',
      '}',
      '',
    ].join('\n');
    const scenario = fixture('', classApi + source);

    expect(
      scenario.diagnostics.files
        .get(scenario.definitionUri)
        ?.items.filter((item) => item.code === 'unused-argument'),
    ).toHaveLength(1);
  });

  test('メソッドの名前付き引数取得を外側の引数使用へ混ぜない', () => {
    const source = [
      '# $option: loader option',
      'load() {',
      '  z.cls.draw Counter',
      '    z.cls.attr count default=0',
      '    z.cls.fn increment',
      '      z.arg.named option "$@"',
      '    z.cls.fn.done',
      '    z.cls.drew',
      '}',
      '',
    ].join('\n');
    const scenario = fixture('', classApi + 'z.arg.named() { : }\n' + source);

    expect(
      scenario.diagnostics.files
        .get(scenario.definitionUri)
        ?.items.filter((item) => item.code === 'unused-argument'),
    ).toHaveLength(1);
  });
});

describe('hydrated class command targets', () => {
  test('未公開と破棄済みのクラスからは解決先を取得しない', () => {
    for (const ending of ['', '  z.cls.abort\n']) {
      const scenario = fixture(
        'z.cls.new Open object\n$object.count.get\n',
        classApi + 'z.cls.draw Open\n  z.cls.attr count default=0\n' + ending,
      );
      const report = scenario.diagnostics.files.get(scenario.document.uri);
      if (!report) throw new Error('Expected caller diagnostics');
      const analysis = analyzeCalls(
        scenario.snapshot,
        report.file,
        report.facts.calls,
        scenario.diagnostics.context,
      );

      expect(analysis.classTargets.size).toBe(0);
    }
  });

  test('同じASTを再利用し、変更したクラスの参照を古いコンテキストへ残さない', () => {
    const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: counterClass });
    const next = createZshFileHydration({
      sourceFile: 'x',
      file: 'x',
      content: counterClass.replace('increment', 'reset'),
    });

    expect(sameClassFiles([file.classes], [file.classes])).toBe(true);
    expect(sameClassFiles([file.classes], [next.classes])).toBe(false);
    const empty = createZshFileHydration({ sourceFile: 'y', file: 'y', content: 'print one\n' });

    expect(sameClassFiles([empty.classes], [])).toBe(true);
  });

  test('呼出し解析が別ファイルのメソッドと属性の宣言を解決先として返す', () => {
    const scenario = fixture(
      'z.cls.new Counter object\n$object.increment\n$object.count.set 1\n',
      classApi + counterClass,
    );
    const report = scenario.diagnostics.files.get(scenario.document.uri);
    if (!report) throw new Error('Expected caller diagnostics');
    const analysis = analyzeCalls(
      scenario.snapshot,
      report.file,
      report.facts.calls,
      scenario.diagnostics.context,
    );
    const targets = [...analysis.classTargets.values()].flat();

    const definition =
      scenario.snapshot.hydrator.files.get('definition.zsh')?.classes.definitions[0];
    if (!definition) throw new Error('Expected class definition');
    const instance = report.file.classes.instances[0];

    expect(targets).toHaveLength(2);
    expect(targets[0].definition).toBe(definition);
    expect(targets[0].instance).toBe(instance);
    expect(targets[0].member).toBe(definition.methods[0]);
    expect(targets[1].definition).toBe(definition);
    expect(targets[1].instance).toBe(instance);
    expect(targets[1].member).toBe(definition.attributes[0]);
  });

  test('実体の変数名をそのまま使った呼び出しを未定義コマンドとして報告する', () => {
    const scenario = fixture(
      [
        'typeset counter',
        'z.cls.new Counter counter',
        '$counter.increment',
        'counter.increment',
        '',
      ].join('\n'),
      classApi + counterClass,
    );

    expect(semantic(scenario.items)).toMatchObject([
      {
        code: 'undefined-command',
        message: 'counter.increment is not defined in the project or shell environment.',
        range: { start: { line: 3, character: 0 } },
      },
    ]);
  });

  test('同名の通常関数が宣言されていれば通常の関数として解決する', () => {
    const scenario = fixture(
      ['typeset counter', 'z.cls.new Counter counter', 'counter.increment', ''].join('\n'),
      classApi + counterClass + 'counter.increment() { :; }\n',
    );
    const report = scenario.diagnostics.files.get(scenario.document.uri);
    if (!report) throw new Error('Expected caller diagnostics');
    const analysis = analyzeCalls(
      scenario.snapshot,
      report.file,
      report.facts.calls,
      scenario.diagnostics.context,
    );
    const command = report.facts.calls.find(
      (call) => call.commandName?.word.raw === 'counter.increment',
    );
    if (!command) throw new Error('Expected dotted command');

    expect(semantic(scenario.items)).toEqual([]);
    expect(analysis.targets.has(command)).toBe(true);
    expect(analysis.classTargets.has(command)).toBe(false);
  });

  test('実体IDを展開する呼び出しがメソッドと属性を解決する', () => {
    const scenario = fixture(
      [
        'z.cls.new Counter counter && $counter.increment',
        '"$counter.increment"',
        '${counter}.count.get',
        '"$counter.count.set" 3',
        '$counter.missing',
        '$unknown.missing',
        '${counter:-other}.missing',
        '$counter.$member',
        '',
      ].join('\n'),
      classApi + counterClass,
    );
    const report = scenario.diagnostics.files.get(scenario.document.uri);
    if (!report) throw new Error('Expected caller diagnostics');
    const analysis = analyzeCalls(
      scenario.snapshot,
      report.file,
      report.facts.calls,
      scenario.diagnostics.context,
    );
    const targets = [...analysis.classTargets.values()].flat();

    expect(
      targets.map(({ instance, member, operation }) => [instance?.name, member.name, operation]),
    ).toEqual([
      ['counter', 'increment', 'method'],
      ['counter', 'increment', 'method'],
      ['counter', 'count', 'get'],
      ['counter', 'count', 'set'],
    ]);
    expect(semantic(scenario.items)).toMatchObject([
      {
        message: '$counter.missing is not defined in class Counter.',
        range: { start: { line: 4 } },
      },
    ]);
  });

  test('初期化より前や別の関数の同名変数から実体を推測しない', () => {
    const scenario = fixture(
      [
        '$counter.unknown',
        'z.cls.new Counter counter',
        'other() { local counter=some_command; $counter.unknown; }',
        'if false; then z.cls.new Counter conditional; fi',
        '$conditional.unknown',
        '',
      ].join('\n'),
      classApi + counterClass,
    );

    expect(semantic(scenario.items)).toEqual([]);
  });

  test('コード引数内の実体は外側のクラスを使い、外側へ漏れない', () => {
    const api = '# $1 [code]: body\nrun() { eval "$1" }\n';
    const scenario = fixture(
      "run 'z.cls.new Counter inside; $inside.missing'\n$inside.missing\n",
      classApi + counterClass + api,
    );

    expect(semantic(scenario.items)).toHaveLength(1);
    expect(semantic(scenario.items)[0]).toMatchObject({
      message: '$inside.missing is not defined in class Counter.',
      range: { start: { line: 0 } },
    });
  });

  test('コード引数内のクラスはそのコード内で解決し、プロジェクトへ漏れない', () => {
    const api = '# $1 [code]: body\nrun() { eval "$1" }\n';
    const text = [
      "run 'z.cls.draw Local",
      '  z.cls.fn value "REPLY=1"',
      '  z.cls.drew',
      'z.cls.new Local local_object',
      "$local_object.missing'",
      'z.cls.new Local outside',
      '$outside.missing',
      '',
    ].join('\n');
    const scenario = fixture(text, classApi + api);

    expect(semantic(scenario.items)).toHaveLength(1);
    expect(semantic(scenario.items)[0].message).toBe(
      '$local_object.missing is not defined in class Local.',
    );

    const report = scenario.diagnostics.files.get(scenario.document.uri);
    const program = report?.codePrograms.find((entry) =>
      entry.file.classes.definitions.some((definition) => definition.name === 'Local'),
    );
    const definition = program?.file.classes.definitions[0];

    expect(definition?.name).toBe('Local');
    expect(definition?.file).toBe(program?.file.ast);
    expect(definition?.methods.map((method) => method.name)).toEqual(['value']);
    expect(program?.file.classes.instances.map((instance) => instance.name)).toEqual([
      'local_object',
    ]);
    expect(program?.root).toBe(report?.file);
  });
  test('defaultを省略した属性を通常の必須引数診断で報告する', () => {
    const scenario = fixture(
      '',
      classApi + ['z.cls.draw MissingDefault', '  z.cls.attr price', '  z.cls.drew', ''].join('\n'),
    );
    const items = scenario.diagnostics.files.get(scenario.definitionUri)?.items ?? [];

    expect(semantic(items)).toMatchObject([
      {
        code: 'missing-named-argument',
        message: 'Missing required named argument: default',
      },
    ]);
    expect(
      scenario.snapshot.hydrator.files.get('definition.zsh')?.classes.definitions[0].state,
    ).toBe('aborted');
  });

  test('公開済みクラスの属性を解決し、拒否されたクラスの属性を報告する', () => {
    const definitions = [
      'z.cls.draw Outer',
      '  z.cls.draw Rejected',
      '    z.cls.attr leaked default=0',
      '    z.cls.drew',
      '  z.cls.attr kept default=1',
      '  z.cls.drew',
      '',
    ].join('\n');
    const scenario = fixture(
      ['z.cls.new Outer object', '$object.kept.get', '$object.leaked.get', ''].join('\n'),
      classApi + definitions,
    );

    expect(semantic(scenario.items)).toMatchObject([
      {
        code: 'undefined-command',
        message: '$object.leaked.get is not defined in class Outer.',
      },
    ]);
  });
});

describe('class ownership diagnostics', () => {
  const ownershipApi = 'z.cls.owner.move() { :; }\n';

  test('移動先を同じクラスに結び付け、古い参照の呼び出しを報告する', () => {
    const scenario = fixture(
      [
        'typeset counter saved final',
        'z.cls.new Counter counter',
        'z.cls.owner.move from=counter to=saved',
        '$counter.increment',
        '$saved.count.get',
        'z.cls.owner.move from=saved to=final || return 1',
        '$saved.increment',
        '$final.count.set 3',
        '$final.missing',
        'z.cls.delete counter',
        '',
      ].join('\n'),
      classApi + ownershipApi + counterClass,
    );

    expect(scenario.items.map(({ code, range }) => [code, range.start.line])).toEqual([
      ['class-reference-moved', 3],
      ['class-reference-moved', 6],
      ['undefined-command', 8],
      ['class-reference-moved', 9],
    ]);

    const report = scenario.diagnostics.files.get(scenario.document.uri);
    if (!report) throw new Error('Expected caller diagnostics');
    const analysis = analyzeCalls(
      scenario.snapshot,
      report.file,
      report.facts.calls,
      scenario.diagnostics.context,
    );
    expect([...analysis.classTargets.values()].flat().map((target) => target.operation)).toEqual([
      'get',
      'set',
    ]);
  });

  test('条件付きの移動や代入先の状態が不明な移動を確定しない', () => {
    const scenario = fixture(
      [
        'typeset counter',
        'z.cls.new Counter counter',
        'if false; then',
        '  typeset saved',
        '  z.cls.owner.move from=counter to=saved',
        'fi',
        'z.cls.owner.move from=counter to=undeclared',
        '$counter.increment',
        '',
      ].join('\n'),
      classApi + ownershipApi + counterClass,
    );
    expect(scenario.items).toEqual([]);
  });

  test('呼び出し元に依存せずreadの属性とメソッドを検査する', () => {
    const members = counterClass.replace(
      '  z.cls.drew',
      "  # $self [Counter<read>]: 参照\n  z.cls.fn value '$self.count.get'\n  z.cls.drew",
    );
    const scenario = fixture(
      [
        '# $1 [Counter<read>]: 読み取り対象',
        'read_count() {',
        '  local -r ref=$1',
        '  $ref.count.get',
        '  $ref.value',
        '  $ref.count.set 8',
        '  $1.increment',
        '  $ref.missing',
        '}',
        '# $1 [Counter<write>]: 更新対象',
        'update_count() { $1.count.set 9; }',
        'typeset counter',
        'z.cls.new Counter counter',
        'read_count "$counter"',
        '',
      ].join('\n'),
      classApi + ownershipApi + members,
    );
    expect(scenario.items.map(({ code, range }) => [code, range.start.line])).toEqual([
      ['class-readonly-write', 5],
      ['class-readonly-write', 6],
      ['undefined-command', 7],
    ]);
  });

  test('所有権引数で指定した変数を呼び出し元で移動済みにする', () => {
    const consumer = [
      '# $from [Counter<owner>]: 受け取る所有変数',
      'consume_counter() {',
      '  z.arg.named from "$@" && local owner_name=$REPLY',
      '  local received=""',
      '  z.cls.owner.move "from=$owner_name" to=received',
      '}',
      '',
    ].join('\n');
    const scenario = fixture(
      [
        'typeset counter',
        'z.cls.new Counter counter',
        'consume_counter from=counter',
        '$counter.count.get',
        '',
      ].join('\n'),
      classApi + ownershipApi + counterClass + consumer,
    );

    expect(scenario.items.map(({ code, range }) => [code, range.start.line])).toEqual([
      ['class-reference-moved', 3],
    ]);
    expect(
      scenario.diagnostics.files.get(scenario.definitionUri)?.items.map((item) => item.code),
    ).not.toContain('class-owner-contract');
  });

  test('所有権を移さずに戻る経路を関数の宣言に報告する', () => {
    const consumer = [
      '# $1 [Counter<owner>]: 受け取る所有変数',
      'consume_counter() {',
      '  local received=""',
      '  if [[ -n "$condition" ]]; then',
      '    return',
      '  fi',
      '  z.cls.owner.move "from=$1" to=received',
      '}',
      '',
    ].join('\n');
    const scenario = fixture('', classApi + ownershipApi + counterClass + consumer);
    expect(
      scenario.diagnostics.files.get(scenario.definitionUri)?.items.map((item) => item.code),
    ).toContain('class-owner-contract');
  });

  test('条件付きで所有権を渡した後の使用を報告する', () => {
    const consumer = [
      '# $1 [Counter<owner>]: 引数の所有変数',
      'consume_counter() {',
      '  local received=""',
      '  z.cls.owner.move "from=$1" to=received',
      '}',
      '',
    ].join('\n');
    const scenario = fixture(
      [
        'typeset counter',
        'z.cls.new Counter counter',
        'if [[ -n "$condition" ]]; then',
        '  consume_counter counter',
        'else',
        '  $counter.count.get',
        'fi',
        '$counter.count.get',
        '',
      ].join('\n'),
      classApi + ownershipApi + counterClass + consumer,
    );
    expect(scenario.items.map(({ code, range }) => [code, range.start.line])).toEqual([
      ['class-reference-moved', 7],
    ]);
    expect(scenario.items[0]?.message).toContain('may have moved');
  });
  test.each(['"target=$ref"', 'target="$ref"', 'target=${ref}'])(
    'readの引数をwriteが必要な通常関数の名前付き引数 %s へ渡すと報告する',
    (argument) => {
      const scenario = fixture(
        [
          '# $target [Counter<write>]: 更新対象',
          'update_count() { z.arg.named target "$@" && local ref=$REPLY; $ref.count.set 1; }',
          '# $1 [Counter<read>]: 読み取り対象',
          'read_count() { local -r ref=$1; update_count ' + argument + '; }',
          '',
        ].join('\n'),
        classApi + ownershipApi + counterClass + 'z.arg.named() { :; }\n',
      );

      expect(scenario.items.map(({ code, range }) => [code, range.start.line])).toEqual([
        ['class-argument-type', 3],
      ]);
    },
  );

  test('両分岐でmoveを通る所有者契約を受理する', () => {
    const scenario = fixture(
      [
        '# $1 [Counter<owner>]: 受け取る所有変数',
        'consume_counter() {',
        '  local received=""',
        '  if [[ -n "$condition" ]]; then',
        '    z.cls.owner.move "from=$1" to=received',
        '  else',
        '    z.cls.owner.move "from=$1" to=received',
        '  fi',
        '}',
        '',
      ].join('\n'),
      classApi + ownershipApi + counterClass,
    );
    expect(scenario.items.map(({ code }) => code)).not.toContain('class-owner-contract');
  });

  test('移動した分岐からreturnする場合は合流後の所有参照を有効に保つ', () => {
    const scenario = fixture(
      [
        '# $1 [Counter<owner>]: 受け取る所有変数',
        'consume_counter() { local received=""; z.cls.owner.move "from=$1" to=received; }',
        'run() {',
        '  local counter=""',
        '  z.cls.new Counter counter',
        '  if [[ -n "$condition" ]]; then',
        '    consume_counter counter',
        '    return',
        '  fi',
        '  $counter.count.get',
        '}',
        '',
      ].join('\n'),
      classApi + ownershipApi + counterClass,
    );
    expect(scenario.items).toEqual([]);
  });
});
