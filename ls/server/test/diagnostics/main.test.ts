import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from 'vitest';
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
import { workspaceDiagnostics } from '../../src/diagnostics/workspace';
import * as facts from '../../src/diagnostics/facts';

const roots: string[] = [];
const environmentRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-diag-shell-'));
let environment: ShellEnvironment = emptyShellEnvironment();
beforeAll(async () => {
  fs.writeFileSync(path.join(environmentRoot, '.zshrc'), [
    "alias fixture-shell-alias='print value'",
    "alias -g FIXTURE_GLOBAL='one two'",
    "alias -s fixture_suffix=cat",
    'fixture-shell-function() { : }', 'autoload -Uz fixture-shell-autoload',
  ].join('\n'));
  environment = await readShellEnvironment({ env: { ...process.env, ZDOTDIR: environmentRoot } });
  expect(environment.kind).toBe('available');
});
afterAll(() => fs.rmSync(environmentRoot, { recursive: true, force: true }));
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
const definition = '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n';
function fixture(content: string, definitions = definition, shell = environment) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-diag-'));
  roots.push(root);
  const definitionUri = pathToFileURL(path.join(root, 'definition.zsh')).href;
  fs.writeFileSync(path.join(root, 'definition.zsh'), definitions);
  const document = TextDocument.create(pathToFileURL(path.join(root, 'caller.zsh')).href, 'shellscript', 1, content);
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: shell });
  return { root, snapshot, diagnostics, document, definitionUri,
    items: validateTextDocument({ diagnostics, textDocument: document }) };
}
const semantic = (items: ReturnType<typeof validateTextDocument>) =>
  items.filter(item => ['missing-positional-argument', 'missing-named-argument', 'undefined-command'].includes(item.code ?? ''));

describe('call diagnostics@AST', () => {
  test('一般名の関数・正確なコマンドrangeと位置番号で不足を判定する', () => {
    expect(semantic(fixture('  "greet" one\n').items)).toMatchObject([{
      code: 'missing-positional-argument', message: 'Missing required argument(s): $2',
      range: { start: { line: 0, character: 2 }, end: { line: 0, character: 9 } },
    }]);
    expect(semantic(fixture('greet one two\n', '# $3: third\ngreet() { print "$3" }\n').items))
      .toMatchObject([{ message: 'Missing required argument(s): $3' }]);
  });
  test.each(['print greet\n', 'print "greet"\n', '# greet\n', 'print > greet\n',
    'greet "one\ntwo" three\n', 'print "$(greet one two)"\n',
    'greet one ' + String.fromCharCode(92) + '\n two\n'])('AST所有関係と複数行: %s', source => {
    expect(semantic(fixture(source).items)).toEqual([]);
  });
  test.each(['greet one | print two\n', 'greet one > two\n',
    'greet one; print two\n', 'greet one && print two\n'])('後続コマンド・redirectを引数へ混ぜない: %s', source => {
    expect(semantic(fixture(source).items)).toMatchObject([{ code: 'missing-positional-argument' }]);
  });
  test.each(['greet $values\n', 'greet "$@"\n', 'greet *\n',
    'greet FIXTURE_GLOBAL\n', 'greet "$' + '{array[@]}"\n'])('展開結果の個数が不明な呼び出しを保留する: %s', source => {
    expect(semantic(fixture(source).items)).toEqual([]);
  });
  test('引用したscalar展開は一つの引数として扱う', () => {
    expect(semantic(fixture('greet "$value"\n').items)).toMatchObject([{ message: 'Missing required argument(s): $2' }]);
  });
  test('名前付き引数を静的なkeyから照合する', () => {
    const doc = '# $option: value\ngreet() { print "$option" }\n';
    expect(semantic(fixture('greet option=""\n', doc).items)).toEqual([]);
    expect(semantic(fixture('greet option=\n', doc).items)).toEqual([]);
    expect(semantic(fixture('greet "option=value"\n', doc).items)).toMatchObject([{ code: 'missing-named-argument' }]);
  });
});

describe('command resolution', () => {
  test.each(['print x\n', 'env\n', 'fixture-shell-alias\n', 'fixture-shell-function\n',
    'fixture-shell-autoload\n', 'file.fixture_suffix\n', 'builtin print x\n',
    'command -v fixture-missing-command\n'])('実Zsh環境の名前を解決する: %s', source => {
    expect(semantic(fixture(source).items)).toEqual([]);
  });
  test('一般名とz名の未定義コマンドを同じルールで診断する', () => {
    for (const command of ['fixture-missing-command', 'z.fixture.missing']) {
      expect(semantic(fixture(command + '\n').items)).toMatchObject([{ code: 'undefined-command' }]);
    }
  });
  test('projectのalias・global/suffix alias・autoload宣言を解決する', () => {
    for (const source of ["alias fixture-local='print x'\nfixture-local\n",
      "alias -g FIXTURE_LOCAL='one two'\ngreet FIXTURE_LOCAL\n",
      "alias -s fixture_local=print\nfile.fixture_local\n",
      'autoload -Uz fixture-local-autoload\nfixture-local-autoload\n']) {
      expect(semantic(fixture(source).items)).toEqual([]);
    }
  });
  test('引用されたalias名と明示modifierを区別する', () => {
    expect(semantic(fixture("'fixture-shell-alias'\n").items)).toMatchObject([{ code: 'undefined-command' }]);
    expect(semantic(fixture('builtin greet\n').items)).toMatchObject([{ code: 'undefined-command' }]);
    expect(semantic(fixture('command greet\n').items)).toMatchObject([{ code: 'undefined-command' }]);
  });
  test('絶対パス・workspaceからの相対パスは実行権限も確認する', () => {
    const f = fixture('./tool\n');
    fs.writeFileSync(path.join(f.root, 'tool'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
    const next = refreshDiagnosticSnapshot({ snapshot: f.snapshot, environment });
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: f.document }))).toEqual([]);
    fs.chmodSync(path.join(f.root, 'tool'), 0o644);
    const unavailable = refreshDiagnosticSnapshot({ snapshot: f.snapshot, environment });
    expect(semantic(validateTextDocument({ diagnostics: unavailable, textDocument: f.document }))).toEqual([]);
    const absolute = TextDocument.create(f.document.uri, 'shellscript', 2, path.join(f.root, 'tool') + '\n');
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [absolute], previous: f.snapshot });
    const checked = refreshDiagnosticSnapshot({ snapshot, environment });
    expect(semantic(validateTextDocument({ diagnostics: checked, textDocument: absolute })))
      .toMatchObject([{ code: 'undefined-command' }]);
  });
  test('動的なcommand wordやcwd依存の相対パスは未定義と断定しない', () => {
    for (const source of ['./fixture-elsewhere\n', '~/bin/fixture-elsewhere\n', '=fixture-command\n', 'fixture-*\n']) {
      expect(semantic(fixture(source).items)).toEqual([]);
    }
  });
  test('環境取得失敗時も既知関数の診断を続け、未解決名をエラーと断定しない', () => {
    expect(semantic(fixture('greet one\nfixture-unknown\n', definition, emptyShellEnvironment()).items))
      .toMatchObject([{ code: 'missing-positional-argument' }]);
  });
});

describe('unused argument documentation@AST', () => {
  test.each(['print "$1"', 'print "$' + '{1}"', 'local value="$1"; print "$value"'])('同じ行の本体・parameterを使用として扱う: %s', body => {
    const f = fixture('', '# $1: value\ngreet() { ' + body + ' }\n');
    expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toEqual([]);
  });
  test.each(["print '$1'", '# $1\n:', 'nested() { print "$1" }'])('文字列・コメント・入れ子の引数使用を除外する: %s', body => {
    const f = fixture('', '# $1: value\ngreet() { ' + body + ' }\n');
    expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toMatchObject([{
      range: { start: { line: 0, character: 2 }, end: { line: 0, character: 4 } },
    }]);
  });
  test.each(['print "$@"', 'print "$*"', '[[ "$1" = x ]]', 'print "$' + '{1:-default}"',
    'print <<END\n$1\nEND\n'])('転送・raw式・展開するheredocの使用は保留する: %s', body => {
    const f = fixture('', '# $1: value\n# $2: other\ngreet() { ' + body + ' }\n');
    expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toEqual([]);
  });
  test('名前付き引数は実際の参照と取得コマンドで使用を判断する', () => {
    for (const body of ['print "$option"', 'z.arg.named option "$@"', 'print "$args[option]"',
      'print "$' + '{args[option]}"']) {
      const f = fixture('', '# $option: value\ngreet() { ' + body + ' }\n');
      expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toEqual([]);
    }
    const f = fixture('', '# $option: value\ngreet() { print option }\n');
    expect(f.diagnostics.files.get(f.definitionUri)?.items.filter(item => item.code === 'unused-argument')).toHaveLength(1);
  });
});

describe('hydrated controls and diagnostics cache', () => {
  test('制御コメントをhydrationから取得し、文字列やexampleのignoreを適用しない', () => {
    expect(semantic(fixture('greet # zls: ignore\n').items)).toEqual([]);
    expect(semantic(fixture('greet # zls: ignore missing-positional-argument\n').items)).toEqual([]);
    expect(semantic(fixture('greet "# zls: ignore"\n').items)).toHaveLength(1);
    expect(semantic(fixture('greet # zls: ignored\n').items)).toHaveLength(1);
    const f = fixture('# example:\n#   zls: ignore\ngreet() { : }\n', '');
    expect(f.diagnostics.files.get(f.document.uri)?.items).toEqual([]);
  });
  test('変更のない解析結果を再利用し、呼び出し編集では他ファイルを再走査しない', () => {
    const f = fixture('greet one two\n');
    const spy = vi.spyOn(facts, 'collectFileFacts');
    expect(refreshDiagnosticSnapshot({ snapshot: f.snapshot, environment, previous: f.diagnostics })).toBe(f.diagnostics);
    const changed = TextDocument.create(f.document.uri, 'shellscript', 2, 'greet one\n');
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [changed], previous: f.snapshot });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(spy).toHaveBeenCalledTimes(1);
    expect(next.files.get(f.definitionUri)).toBe(f.diagnostics.files.get(f.definitionUri));
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: changed }))).toHaveLength(1);
    expect(validateTextDocument({ diagnostics: next, textDocument: f.document })).toEqual([]);
  });
  test('workspace外のaliasはその文書へ適用し、projectへ混ぜない', () => {
    const f = fixture('fixture-outside-alias\n');
    const outside = TextDocument.create(pathToFileURL(path.join(path.dirname(f.root), 'outside.zsh')).href,
      'shellscript', 1, "alias fixture-outside-alias='print x'\nfixture-outside-alias\n");
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document, outside], previous: f.snapshot });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: outside }))).toEqual([]);
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: f.document }))).toHaveLength(1);
    expect(workspaceDiagnostics({ diagnostics: next }).items.some(item => item.uri === outside.uri)).toBe(false);
  });
  test('workspace外の関数はその文書の診断に使い、projectへ混ぜない', () => {
    const f = fixture('fixture-outside-function\n');
    const outside = TextDocument.create(pathToFileURL(path.join(path.dirname(f.root), 'outside.zsh')).href,
      'shellscript', 1, '# $1: value\nfixture-outside-function() { print "$1" }\nfixture-outside-function\n');
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document, outside], previous: f.snapshot });
    const next = refreshDiagnosticSnapshot({ snapshot, environment });
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: outside })))
      .toMatchObject([{ code: 'missing-positional-argument' }]);
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: f.document })))
      .toMatchObject([{ code: 'undefined-command' }]);
  });
  test('calleeのドキュメント変更で未編集の呼び出しを再評価する', () => {
    const f = fixture('greet one two\n');
    const changed = TextDocument.create(f.definitionUri, 'shellscript', 1, '# $3: third\ngreet() { print "$3" }\n');
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document, changed], previous: f.snapshot });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(next.files.get(f.document.uri)?.facts).toBe(f.diagnostics.files.get(f.document.uri)?.facts);
    expect(semantic(validateTextDocument({ diagnostics: next, textDocument: f.document }))).toHaveLength(1);
  });
  test('workspaceレポートはopen versionと未保存ファイルを含み、削除済みの結果を空にする', () => {
    const f = fixture('greet one\n');
    const report = workspaceDiagnostics({ diagnostics: f.diagnostics,
      previousResultIds: [{ uri: 'file:///removed.zsh', value: 'old' }] });
    expect(report.items.find(item => item.uri === f.document.uri)).toMatchObject({ version: 1, resultId: expect.any(String), items: expect.any(Array) });
    expect(report.items.find(item => item.uri === f.definitionUri)?.version).toBeNull();
    expect(report.items.find(item => item.uri === 'file:///removed.zsh')?.items).toEqual([]);
  });
  test('CRLFの書式診断は改行を含まないLSP範囲を返す', () => {
    const f = fixture(' \r\nprint x\r\n');
    expect(f.items.find(item => item.code === 'empty-line')?.range.end).toEqual({ line: 0, character: 1 });
  });
  test('構文・文書診断を分けて返し、書式診断をliteral内部へ適用しない', () => {
    expect(fixture('print "unfinished\n').items.some(item => item.source === 'z-ls/lexer')).toBe(true);
    expect(fixture('if true; then\n').items.some(item => item.source === 'z-ls/parser')).toBe(true);
    expect(fixture('print "a\n  \nb"\n').items.filter(item => item.code === 'empty-line')).toEqual([]);
    const last = fixture('print x\nprint y').items.find(item => item.code === 'final-newline');
    expect(last?.range.start).toEqual({ line: 1, character: 7 });
  });
});
