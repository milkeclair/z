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
import { classCommands, sameClassFiles } from '../../src/diagnostics/classes';
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
    pathToFileURL(path.join(root, 'caller.zsh')).href, 'shellscript', 1, content,
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
  items.filter(item => ['missing-positional-argument', 'missing-named-argument', 'undefined-command']
    .includes(item.code ?? ''));

const classApi = [
  'z.cls.draw() { : }',
  'z.cls.attr() { : }',
  '# $1: method name',
  '# $2? [code]: inline body',
  'z.cls.fn() { : "$@" }',
  'z.cls.fn.done() { : }',
  'z.cls.drew() { : }',
  'z.cls.new() { : }',
].join('\n') + '\n';
const counterClass = [
  'z.cls.draw Counter; {',
  '  z.cls.attr count 0',
  '  z.cls.fn increment',
  '    (( ++count ))',
  '  z.cls.fn.done',
  '  z.cls.drew',
  '}', '',
].join('\n');

describe('class DSL command diagnostics', () => {
  test('inlineメソッド本体はmainのcode引数診断で元位置に報告する', () => {
    const source = counterClass.replace('z.cls.fn increment\n    (( ++count ))\n  z.cls.fn.done',
      "z.cls.fn increment 'missing_inline_method'");
    const scenario = fixture('', classApi + source);
    const diagnostics = scenario.diagnostics.files.get(scenario.definitionUri)?.items.filter(item => item.code === 'undefined-command') ?? [];

    expect(diagnostics).toHaveLength(1);
    expect(diagnostics[0].message).toContain('missing_inline_method');
    expect(diagnostics[0].range.start.line).toBe(10);
  });

  test('別ファイルのクラスから生成されるメソッドと属性を認識し、タイプミスは診断する', () => {
    const scenario = fixture('z.cls.new Counter counter\ncounter.increment\ncounter.count.get\ncounter.count.set 3\ncounter.typo\n',
      classApi + counterClass);

    expect(semantic(scenario.items)).toMatchObject([{ code: 'undefined-command',
      message: 'counter.typo is not defined in the project or shell environment.' }]);

    expect(semantic(scenario.items)).toHaveLength(1);
  });

  test('メソッド内の未定義コマンドを元ファイルの位置で診断する', () => {
    const source = counterClass.replace('(( ++count ))', 'missing_inside_method');
    const scenario = fixture('', classApi + source);

    expect(semantic(scenario.diagnostics.files.get(scenario.definitionUri)?.items ?? [])).toMatchObject([{
      code: 'undefined-command', range: { start: { line: 11, character: 4 } },
    }]);
  });

  test('メソッドの編集で未編集の呼出元を再診断する', () => {
    const scenario = fixture('z.cls.new Counter counter\ncounter.increment\n', classApi + counterClass);

    expect(semantic(scenario.items)).toEqual([]);

    const changed = TextDocument.create(scenario.definitionUri, 'shellscript', 1,
      classApi + counterClass.replace('z.cls.fn increment', 'z.cls.fn reset'));

    const snapshot = refreshFunctionSnapshot({
      projectRoot: scenario.root,
      documents: [scenario.document, changed],
      previous: scenario.snapshot,
    });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: scenario.diagnostics });

    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: scenario.document })))
      .toMatchObject([{ code: 'undefined-command' }]);
  });

  test('入れ子の関数や文字列内の終了名でメソッドを閉じない', () => {
    const source = counterClass.replace('(( ++count ))',
      'helper() { z.cls.fn.done }\n    print "z.cls.fn.done"\n    z.cls.fn imaginary');
    const scenario = fixture('z.cls.new Counter counter\ncounter.increment\ncounter.imaginary\n', classApi + source);

    expect(semantic(scenario.items)).toHaveLength(1);
    expect(semantic(scenario.items)[0]?.message).toContain('counter.imaginary');
  });
});

describe('scoped class references', () => {
  test('スコープによって異なるクラスを指す同名変数の呼出を認識する', () => {
    const arrayClass = ['z.cls.draw ArrayBox; {', 'z.cls.fn fill', ':', 'z.cls.fn.done', 'z.cls.drew', '}', ''].join('\n');
    const source = ['z.cls.new Counter counter', 'counter.increment', 'inner() {', 'local counter=""',
      'z.cls.new ArrayBox counter', 'counter.fill', '}', 'counter.count.get', ''].join('\n');

    expect(semantic(fixture(source, classApi + counterClass + arrayClass).items)).toEqual([]);
  });

  test('外側の関数の引数使用へメソッド内の引数を混ぜない', () => {
    const source = '# $1: loader argument\nload() {\n' +
      counterClass.replace('(( ++count ))', 'print "$1"') + '}\n';
    const scenario = fixture('', classApi + source);

    expect(scenario.diagnostics.files.get(scenario.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toHaveLength(1);
  });

  test('メソッドの名前付き引数取得を外側の引数使用へ混ぜない', () => {
    const source = '# $option: loader option\nload() {\n' +
      counterClass.replace('(( ++count ))', 'z.arg.named option "$@"') + '}\n';
    const scenario = fixture('', classApi + 'z.arg.named() { : }\n' + source);

    expect(scenario.diagnostics.files.get(scenario.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toHaveLength(1);
  });
});

describe('hydrated class command targets', () => {
  test('別ファイルのclassとinstanceを実際のメンバーノードへ結び付ける', () => {
    const definitions = createZshFileHydration({ sourceFile: '/defs.zsh', file: 'defs.zsh', content: counterClass });
    const bindings = createZshFileHydration({ sourceFile: '/caller.zsh', file: 'caller.zsh', content: 'z.cls.new Counter object\n' });
    const targets = classCommands([definitions.classes, bindings.classes]);
    const method = targets.get('object.increment')?.[0];

    expect(method?.definition).toBe(definitions.classes.definitions[0]);
    expect(method?.member).toBe(definitions.classes.definitions[0].methods[0]);
    expect(method?.instance).toBe(bindings.classes.instances[0]);
    expect(method?.operation).toBe('method');
    expect(targets.get('object.count.set')?.[0].member).toBe(definitions.classes.definitions[0].attributes[0]);
  });

  test('未公開とabortのclassからはターゲットを生成しない', () => {
    for (const ending of ['', 'z.cls.abort\n']) {
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x',
        content: 'z.cls.draw Open\nz.cls.attr count 0\n' + ending + 'z.cls.new Open object\n' });

      expect(classCommands([file.classes]).size).toBe(0);
    }
  });

  test('同じASTを再利用し、変更したclassの参照は古いcontextへ残さない', () => {
    const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: counterClass });
    const next = createZshFileHydration({ sourceFile: 'x', file: 'x', content: counterClass.replace('increment', 'reset') });

    expect(sameClassFiles([file.classes], [file.classes])).toBe(true);
    expect(sameClassFiles([file.classes], [next.classes])).toBe(false);
    const empty = createZshFileHydration({ sourceFile: 'y', file: 'y', content: 'print one\n' });

    expect(sameClassFiles([empty.classes], [])).toBe(true);
  });

  test('呼出解析がclassメンバーの解決先を名前の除外だけでなく返す', () => {
    const scenario = fixture('z.cls.new Counter object\nobject.increment\n', classApi + counterClass);
    const report = scenario.diagnostics.files.get(scenario.document.uri);
    if (!report) throw new Error('Expected caller diagnostics');
    const analysis = analyzeCalls(scenario.snapshot, report.file, report.facts.calls, scenario.diagnostics.context);
    const targets = [...analysis.classTargets.values()].flat();

    expect(targets).toHaveLength(1);
    expect(targets[0].member).toMatchObject({ kind: 'classMethod', name: 'increment' });
    expect(targets[0].member.declaration.commandName?.word.raw).toBe('z.cls.fn');
  });

  test('code引数内のinstanceは外側のclassを使い、外側へ漏れない', () => {
    const api = '# $1 [code]: body\nrun() { eval "$1" }\n';
    const scenario = fixture("run 'z.cls.new Counter inside; inside.increment'\ninside.increment\n", classApi + counterClass + api);

    expect(semantic(scenario.items)).toHaveLength(1);
    expect(semantic(scenario.items)[0].range.start.line).toBe(1);
  });

  test('code引数内のclassはそのcode内で解決し、projectへ漏れない', () => {
    const api = '# $1 [code]: body\nrun() { eval "$1" }\n';
    const text = "run 'z.cls.draw Local; z.cls.fn value \"REPLY=1\"; z.cls.drew; z.cls.new Local local_object; local_object.value'\n" +
      'z.cls.new Local outside\noutside.value\n';
    const scenario = fixture(text, classApi + api);

    expect(semantic(scenario.items)).toHaveLength(1);
    expect(semantic(scenario.items)[0].message).toContain('outside.value');
  });
});
