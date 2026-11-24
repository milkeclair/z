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
import { writeClassApi } from '../support/classApi';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();
const environmentRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-class-diag-shell-'));
let environment: ShellEnvironment = emptyShellEnvironment();
beforeAll(async () => {
  fs.writeFileSync(path.join(environmentRoot, '.zshrc'), '');
  environment = await readShellEnvironment({ env: { ...process.env, ZDOTDIR: environmentRoot } });

  expect(environment.kind).toBe('available');
});
afterAll(() => fs.rmSync(environmentRoot, { recursive: true, force: true }));
afterEach(() => {
  temporaryDirectories.cleanup();
});

function fixture(content: string, definitions: string) {
  const root = temporaryDirectories.create('z-class-diag-');
  writeClassApi(root);

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

const counterClass = [
  'z.cls.draw Counter',
  '  z.cls.attr count default=0',
  '  z.cls.method increment',
  '    (( ++count ))',
  '  z.cls.method.defined',
  '  z.cls.drew',
  '',
].join('\n');

describe('validateTextDocument', () => {
  describe('クラスDSLを診断する場合', () => {
    test('引数形式のメソッド本体は共通のコード引数解析で元位置に診断する', () => {
      const source = counterClass.replace(
        'z.cls.method increment\n    (( ++count ))\n  z.cls.method.defined',
        "z.cls.method increment 'missing_inline_method'",
      );
      const scenario = fixture('', source);
      const diagnostics =
        scenario.diagnostics.files
          .get(scenario.definitionUri)
          ?.items.filter((item) => item.code === 'undefined-command') ?? [];

      expect(diagnostics).toHaveLength(1);
      expect(diagnostics[0].message).toContain('missing_inline_method');
      expect(diagnostics[0].range.start.line).toBe(2);
    });

    test('別ファイルのクラスに存在しないメンバー名を診断する', () => {
      const scenario = fixture(
        'z.cls.new Counter counter\n$counter.increment\n$counter.count.get\n$counter.count.set 3\n$counter.typo\n',
        counterClass,
      );

      expect(semantic(scenario.items)).toMatchObject([
        {
          code: 'undefined-command',
          message: '$counter.typo is not defined in class Counter.',
        },
      ]);
    });

    test('メソッド内の未定義コマンドを元ファイルの位置で診断する', () => {
      const source = counterClass.replace('(( ++count ))', 'missing_inside_method');
      const scenario = fixture('', source);

      expect(
        semantic(scenario.diagnostics.files.get(scenario.definitionUri)?.items ?? []),
      ).toMatchObject([
        {
          code: 'undefined-command',
          range: { start: { line: 3, character: 4 } },
        },
      ]);
    });

    test('メソッド名の変更で未編集の呼び出し元を再診断する', () => {
      const scenario = fixture('z.cls.new Counter counter\n$counter.increment\n', counterClass);

      expect(semantic(scenario.items)).toEqual([]);

      const changed = TextDocument.create(
        scenario.definitionUri,
        'shellscript',
        1,
        counterClass.replace('z.cls.method increment', 'z.cls.method reset'),
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
        'helper() { z.cls.method.defined }\n    print "z.cls.method.defined"\n    z.cls.method imaginary',
      );
      const scenario = fixture(
        'z.cls.new Counter counter\n$counter.increment\n$counter.imaginary\n',
        source,
      );

      expect(semantic(scenario.items)).toHaveLength(1);
      expect(semantic(scenario.items)[0]?.message).toContain('counter.imaginary');
    });
  });

  describe('実体の所属するスコープを解決する場合', () => {
    test('同名の変数をスコープごとに異なるクラスへ解決する', () => {
      const arrayClass = [
        'z.cls.draw ArrayBox',
        '  z.cls.method fill',
        '    :',
        '  z.cls.method.defined',
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

      const scenario = fixture(source, counterClass + arrayClass);

      expect(semantic(scenario.items).map((item) => item.message)).toEqual([
        '$counter.increment is not defined in class ArrayBox.',
        '$counter.fill is not defined in class Counter.',
      ]);
    });

    test('プロジェクト外の文書はプロジェクトと文書内のクラスを使い、文書内の定義は外へ漏れない', () => {
      const scenario = fixture('z.cls.new Local leaked\n$leaked.value\n', counterClass);
      const outside = TextDocument.create(
        pathToFileURL(path.join(path.dirname(scenario.root), 'outside.zsh')).href,
        'shellscript',
        1,
        [
          'z.cls.draw Local',
          '  z.cls.method value "REPLY=1"',
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
        '    z.cls.method increment',
        '      print "$1"',
        '    z.cls.method.defined',
        '    z.cls.drew',
        '}',
        '',
      ].join('\n');
      const scenario = fixture('', source);

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
        '    z.cls.method increment',
        '      z.arg.named option "$@"',
        '    z.cls.method.defined',
        '    z.cls.drew',
        '}',
        '',
      ].join('\n');
      const scenario = fixture('', source);

      expect(
        scenario.diagnostics.files
          .get(scenario.definitionUri)
          ?.items.filter((item) => item.code === 'unused-argument'),
      ).toHaveLength(1);
    });
  });

  describe('クラスの宣言元を照合する場合', () => {
    test('未公開と破棄済みのクラスからは解決先を取得しない', () => {
      for (const ending of ['', '  z.cls.abort\n']) {
        const scenario = fixture(
          'z.cls.new Open object\n$object.count.get\n',
          'z.cls.draw Open\n  z.cls.attr count default=0\n' + ending,
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

    test('同じASTのクラス宣言を再利用できると判定する', () => {
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: counterClass });

      expect(sameClassFiles([file.classes], [file.classes])).toBe(true);
    });

    test('メソッド名を編集したASTは以前のクラス宣言を使わない', () => {
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: counterClass });
      const edited = createZshFileHydration({
        sourceFile: 'x',
        file: 'x',
        content: counterClass.replace('increment', 'reset'),
      });

      expect(sameClassFiles([file.classes], [edited.classes])).toBe(false);
    });

    test('クラス宣言のないファイルを追加してもクラス索引を再利用できる', () => {
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: 'print one\n' });

      expect(sameClassFiles([file.classes], [])).toBe(true);
    });

    test('別ファイルのメソッドと属性の宣言を呼び出し先として返す', () => {
      const scenario = fixture(
        'z.cls.new Counter object\n$object.increment\n$object.count.set 1\n',
        counterClass,
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

    test('変数展開のないメソッド呼び出しを未定義コマンドとして報告する', () => {
      const scenario = fixture(
        [
          'typeset counter',
          'z.cls.new Counter counter',
          '$counter.increment',
          'counter.increment',
          '',
        ].join('\n'),
        counterClass,
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
        counterClass + 'counter.increment() { :; }\n',
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

    test('インスタンスIDを展開してメソッドと属性を解決する', () => {
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
        counterClass,
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

    test('初期化前の参照と別関数の同名変数をインスタンスへ結び付けない', () => {
      const scenario = fixture(
        [
          '$counter.unknown',
          'z.cls.new Counter counter',
          'other() { local counter=some_command; $counter.unknown; }',
          'if false; then z.cls.new Counter conditional; fi',
          '$conditional.unknown',
          '',
        ].join('\n'),
        counterClass,
      );

      expect(semantic(scenario.items)).toEqual([]);
    });

    test('コード引数内のインスタンスをその引数内で解決する', () => {
      const api = '# $1 [code]: body\nrun() { eval "$1" }\n';
      const scenario = fixture(
        "run 'z.cls.new Counter inside; $inside.missing'\n$inside.missing\n",
        counterClass + api,
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
        '  z.cls.method value "REPLY=1"',
        '  z.cls.drew',
        'z.cls.new Local local_object',
        "$local_object.missing'",
        'z.cls.new Local outside',
        '$outside.missing',
        '',
      ].join('\n');
      const scenario = fixture(text, api);

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
        ['z.cls.draw MissingDefault', '  z.cls.attr price', '  z.cls.drew', ''].join('\n'),
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
        definitions,
      );

      expect(semantic(scenario.items)).toMatchObject([
        {
          code: 'undefined-command',
          message: '$object.leaked.get is not defined in class Outer.',
        },
      ]);
    });
  });

  describe('所有権の移動と更新契約を診断する場合', () => {
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
        ownershipApi + counterClass,
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

    test('deleteの引数にある等号付き文字列を移動元変数名として扱わない', () => {
      const source = [
        'typeset counter saved',
        'z.cls.new Counter counter',
        'z.cls.owner.move from=counter to=saved',
        "z.cls.delete '=counter'",
        '$counter.increment',
        '',
      ].join('\n');

      const scenario = fixture(source, ownershipApi + counterClass);

      expect(scenario.items).toMatchObject([
        { code: 'class-reference-moved', range: { start: { line: 4 } } },
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
        ownershipApi + counterClass,
      );
      expect(scenario.items).toEqual([]);
    });

    test('呼び出し元に依存せずreadの属性とメソッドを検査する', () => {
      const members = counterClass.replace(
        '  z.cls.drew',
        "  # $self [Counter<read>]: 参照\n  z.cls.method value '$self.count.get'\n  z.cls.drew",
      );
      const scenario = fixture(
        [
          '# $1 [Counter<read>]: 読み取り対象のインスタンス',
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
        ownershipApi + members,
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
        ownershipApi + counterClass + consumer,
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
      const scenario = fixture('', ownershipApi + counterClass + consumer);
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
        ownershipApi + counterClass + consumer,
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
            '# $1 [Counter<read>]: 読み取り対象のインスタンス',
            'read_count() { local -r ref=$1; update_count ' + argument + '; }',
            '',
          ].join('\n'),
          ownershipApi + counterClass,
        );

        expect(scenario.items.map(({ code, range }) => [code, range.start.line])).toEqual([
          ['class-argument-type', 3],
        ]);
      },
    );

    test('個数不明の展開以降は名前付きのクラス引数だけを診断する', () => {
      const source = [
        '# $1 [Counter<read>]: 読み取り対象のインスタンス',
        'caller() {',
        '  local -r ref=$1',
        '  update "$@" not_a_reference',
        '  update "$@" target="$ref"',
        '}',
        '',
      ].join('\n');
      const definitions = [
        '# $2 [Counter<write>]: 位置引数で受け取るインスタンス',
        '# $target? [Counter<write>]: 名前付き引数で受け取るインスタンス',
        'update() { : "$@"; }',
        '',
      ].join('\n');

      const scenario = fixture(source, definitions);

      expect(scenario.items).toMatchObject([
        { code: 'class-argument-type', range: { start: { line: 4 } } },
      ]);
    });

    test('クラス引数に型エラーがあっても同じ呼び出しのコード引数を解析する', () => {
      const source = "mixed nope 'missing_inline_command'\n";
      const definitions = [
        '# $1 [Counter<read>]: 読み取り対象のインスタンス',
        '# $2 [code]: 実行するコマンド',
        'mixed() { : "$@"; }',
        '',
      ].join('\n');

      const scenario = fixture(source, definitions);

      expect(scenario.diagnostics.files.get(scenario.document.uri)?.codePrograms).toHaveLength(1);
      expect(scenario.items).toMatchObject([
        { code: 'class-argument-type', range: { start: { character: 0 } } },
        {
          code: 'undefined-command',
          range: { start: { character: source.indexOf('missing_inline_command') } },
        },
      ]);
    });

    test('すべての分岐で所有権を移す関数の契約を受理する', () => {
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
        ownershipApi + counterClass,
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
        ownershipApi + counterClass,
      );
      expect(scenario.items).toEqual([]);
    });
  });
});
