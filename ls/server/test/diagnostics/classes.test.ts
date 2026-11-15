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
  const document = TextDocument.create(pathToFileURL(path.join(root, 'caller.zsh')).href, 'shellscript', 1, content);
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment });
  return { root, snapshot, diagnostics, document, definitionUri,
    items: validateTextDocument({ diagnostics, textDocument: document }) };
}
const semantic = (items: Readonly<ReturnType<typeof validateTextDocument>>) =>
  items.filter(item => ['missing-positional-argument', 'missing-named-argument', 'undefined-command'].includes(item.code ?? ''));

const classApi = ['z.cls.draw() { : }', 'z.cls.attr() { : }', 'z.cls.fn() { : }',
  'z.cls.fn.done() { : }', 'z.cls.drew() { : }', 'z.cls.new() { : }'].join('\n') + '\n';
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
  test('別ファイルのクラスから生成されるメソッドと属性を認識し、タイプミスは診断する', () => {
    const f = fixture('z.cls.new Counter counter\ncounter.increment\ncounter.count.get\ncounter.count.set 3\ncounter.typo\n',
      classApi + counterClass);
    expect(semantic(f.items)).toMatchObject([{ code: 'undefined-command',
      message: 'counter.typo is not defined in the project or shell environment.' }]);
    expect(semantic(f.items)).toHaveLength(1);
  });

  test('メソッド内の未定義コマンドを元ファイルの位置で診断する', () => {
    const source = counterClass.replace('(( ++count ))', 'missing_inside_method');
    const f = fixture('', classApi + source);
    expect(semantic(f.diagnostics.files.get(f.definitionUri)?.items ?? [])).toMatchObject([{
      code: 'undefined-command', range: { start: { line: 9, character: 4 } },
    }]);
  });

  test('メソッドの編集で未編集の呼出元を再診断する', () => {
    const f = fixture('z.cls.new Counter counter\ncounter.increment\n', classApi + counterClass);
    expect(semantic(f.items)).toEqual([]);
    const changed = TextDocument.create(f.definitionUri, 'shellscript', 1,
      classApi + counterClass.replace('z.cls.fn increment', 'z.cls.fn reset'));
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document, changed], previous: f.snapshot });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: f.document })))
      .toMatchObject([{ code: 'undefined-command' }]);
  });

  test('入れ子の関数や文字列内の終了名でメソッドを閉じない', () => {
    const source = counterClass.replace('(( ++count ))',
      'helper() { z.cls.fn.done }\n    print "z.cls.fn.done"\n    z.cls.fn imaginary');
    const f = fixture('z.cls.new Counter counter\ncounter.increment\ncounter.imaginary\n', classApi + source);
    expect(semantic(f.items)).toHaveLength(1);
    expect(semantic(f.items)[0]?.message).toContain('counter.imaginary');
  });
});

describe('scoped class references', () => {
  test('スコープによって異なるクラスを指す同名変数の呼出を認識する', () => {
    const arrayClass = ['z.cls.draw ArrayBox; {', 'z.cls.fn fill', ':', 'z.cls.fn.done', 'z.cls.drew', '}', ''].join('\n');
    const source = ['z.cls.new Counter counter', 'counter.increment', 'inner() {', 'local counter',
      'z.cls.new ArrayBox counter', 'counter.fill', '}', 'counter.count.get', ''].join('\n');
    expect(semantic(fixture(source, classApi + counterClass + arrayClass).items)).toEqual([]);
  });

  test('外側の関数の引数使用へメソッド内の引数を混ぜない', () => {
    const source = '# $1: loader argument\nload() {\n' +
      counterClass.replace('(( ++count ))', 'print "$1"') + '}\n';
    const f = fixture('', classApi + source);
    expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toHaveLength(1);
  });

  test('メソッドの名前付き引数取得を外側の引数使用へ混ぜない', () => {
    const source = '# $option: loader option\nload() {\n' +
      counterClass.replace('(( ++count ))', 'z.arg.named option "$@"') + '}\n';
    const f = fixture('', classApi + 'z.arg.named() { : }\n' + source);
    expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toHaveLength(1);
  });
});
