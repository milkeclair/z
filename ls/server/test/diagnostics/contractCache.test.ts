import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import type { FunctionSnapshot } from '../../src/refreshFunctions/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import type { DiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { readShellEnvironment, emptyShellEnvironment } from '../../src/diagnostics/environment';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import * as calls from '../../src/diagnostics/calls';
import { zHover } from '../../src/connection/hover';
import { zDefinition } from '../../src/connection/definition';

const roots: string[] = [];
const shellRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-contract-shell-'));
let environment: ShellEnvironment = emptyShellEnvironment();
beforeAll(async () => {
  fs.writeFileSync(path.join(shellRoot, '.zshrc'), '');
  environment = await readShellEnvironment({ env: { ...process.env, ZDOTDIR: shellRoot } });
  expect(environment.kind).toBe('available');
});
afterAll(() => fs.rmSync(shellRoot, { recursive: true, force: true }));
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
const original = '# Original docs\n# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\nsecond() { : }\n';
function fixture(definitions = original, caller = 'greet one\n') {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-contract-cache-'));
  roots.push(root);
  const filename = path.join(root, 'definitions.zsh');
  fs.writeFileSync(filename, definitions);
  const uri = pathToFileURL(filename).href;
  const document = TextDocument.create(pathToFileURL(path.join(root, 'caller.zsh')).href, 'shellscript', 1, caller);
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment });
  return { root, filename, uri, document, snapshot, diagnostics };
}
type State = { readonly snapshot: FunctionSnapshot; readonly diagnostics: DiagnosticSnapshot };
function update(f: ReturnType<typeof fixture>, text: string, previous: State = f, version = 1): State {
  const changed = TextDocument.create(f.uri, 'shellscript', version, text);
  const snapshot = refreshFunctionSnapshot({ projectRoot: f.root,
    documents: [f.document, changed], previous: previous.snapshot });
  return { snapshot, diagnostics: refreshDiagnosticSnapshot({ snapshot, environment, previous: previous.diagnostics }) };
}
function parity(state: State): void {
  const fresh = refreshDiagnosticSnapshot({ snapshot: state.snapshot, environment });
  expect([...state.diagnostics.files.keys()]).toEqual([...fresh.files.keys()]);
  for (const [uri, report] of state.diagnostics.files) expect(report.items).toEqual(fresh.files.get(uri)?.items);
}
function messages(state: State, uri: string): string[] {
  return state.diagnostics.files.get(uri)?.items.map(item => item.message) ?? [];
}

describe('diagnostic call contract cache', () => {
  test('本文編集で宣言位置が動いても未編集callerを再利用し、変更ファイルの使用状況は更新する', () => {
    const f = fixture();
    const spy = vi.spyOn(calls, 'callDiagnostics');
    const next = update(f, original.replace('print "$1" "$2"', ':'));
    expect(next.snapshot.targets).not.toBe(f.snapshot.targets);
    expect(next.snapshot.targets.get('second')?.[0].nameNode.range.start.offset)
      .not.toBe(f.snapshot.targets.get('second')?.[0].nameNode.range.start.offset);
    expect(spy).toHaveBeenCalledTimes(1);
    expect(next.diagnostics.files.get(f.document.uri)).toBe(f.diagnostics.files.get(f.document.uri));
    expect(next.diagnostics.files.get(f.document.uri)?.resultId).toBe(f.diagnostics.files.get(f.document.uri)?.resultId);
    expect(next.diagnostics.targets).toBe(next.snapshot.targets);
    expect(next.diagnostics.files.get(f.uri)?.file).toBe(next.snapshot.hydrator.files.get('definitions.zsh'));
    expect(next.diagnostics.files.get(f.uri)?.items.filter(item => item.code === 'unused-argument')).toHaveLength(2);
    parity(next);
  });

  test('説明文と位置の変更をhover/定義へ反映しながらcaller診断を再利用する', () => {
    const f = fixture();
    const next = update(f, original.replace('# Original docs', '# Edited documentation\n# Additional explanation'));
    expect(next.diagnostics.files.get(f.document.uri)).toBe(f.diagnostics.files.get(f.document.uri));
    const documents = { get: (uri: string) => uri === f.document.uri ? f.document : undefined };
    const params = { textDocument: { uri: f.document.uri }, position: { line: 0, character: 2 } };
    expect(zHover({ params, documents, snapshot: next.snapshot })).toMatchObject({
      contents: { value: expect.stringContaining('Edited documentation') },
    });
    expect(zDefinition({ params, documents, snapshot: next.snapshot })?.range.start.line).toBe(4);
    parity(next);
  });

  test.each([
    ['位置番号', '# $1: first\ngreet() { print "$1" }\n', '# $2: second\ngreet() { print "$2" }\n', 'greet one\n'],
    ['必須から任意', '# $2: second\ngreet() { print "$2" }\n', '# $2?: second\ngreet() { print "$2" }\n', 'greet one\n'],
    ['名前付き引数', '# $option: value\ngreet() { print "$option" }\n', '# $other: value\ngreet() { print "$other" }\n', 'greet option=value\n'],
    ['引数種類', '# $1: first\ngreet() { print "$1" }\n', '# $option: value\ngreet() { print "$option" }\n', 'greet one\n'],
    ['残余引数', '# $@: all\ngreet() { print "$@" }\n', '# $*: all\ngreet() { print "$*" }\n', 'greet\n'],
    ['引数の元の順序', '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n',
      '# $2: second\n# $1: first\ngreet() { print "$1" "$2" }\n', 'greet\n'],
    ['関数名', 'greet() { : }\n', 'renamed() { : }\n', 'greet\n'],
    ['関数追加', '', 'greet() { : }\n', 'greet\n'],
    ['関数削除', 'greet() { : }\n', '', 'greet\n'],
  ])('%sの変更ではcallerを再診断する', (_, before, after, caller) => {
    const f = fixture(before, caller);
    const next = update(f, after);
    expect(next.diagnostics.files.get(f.document.uri)).not.toBe(f.diagnostics.files.get(f.document.uri));
    expect(next.diagnostics.files.get(f.document.uri)?.resultId).not.toBe(f.diagnostics.files.get(f.document.uri)?.resultId);
    parity(next);
  });

  test('同名定義の順序変更で解決先の引数仕様を再評価する', () => {
    const first = '# $1: first\ngreet() { print "$1" }\n';
    const second = '# $2: second\ngreet() { print "$2" }\n';
    const f = fixture(first + second);
    expect(messages(f, f.document.uri)).toEqual([]);
    const next = update(f, second + first);
    expect(messages(next, f.document.uri)).toContain('Missing required argument(s): $2');
    parity(next);
  });

  test('定義ファイルの移動でグローバル候補が変わる場合を検出する', () => {
    const f = fixture('# $1: first\ngreet() { print "$1" }\n');
    fs.writeFileSync(path.join(f.root, 'later.zsh'), '# $2: second\ngreet() { print "$2" }\n');
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document], previous: f.snapshot });
    const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    fs.renameSync(f.filename, path.join(f.root, 'z-last.zsh'));
    const movedSnapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document], previous: snapshot });
    const moved = { snapshot: movedSnapshot, diagnostics: refreshDiagnosticSnapshot({
      snapshot: movedSnapshot, environment, previous: diagnostics,
    }) };
    expect(messages(moved, f.document.uri)).toContain('Missing required argument(s): $2');
    parity(moved);
  });

  test('引数仕様が同じでも候補URIの変更では再診断する', () => {
    const f = fixture();
    fs.renameSync(f.filename, path.join(f.root, 'moved.zsh'));
    const snapshot = refreshFunctionSnapshot({ projectRoot: f.root, documents: [f.document], previous: f.snapshot });
    const next = { snapshot, diagnostics: refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics }) };
    expect(snapshot.targets.get('greet')?.[0].uri).not.toBe(f.snapshot.targets.get('greet')?.[0].uri);
    expect(next.diagnostics.files.get(f.document.uri)).not.toBe(f.diagnostics.files.get(f.document.uri));
    expect(messages(next, f.document.uri)).toEqual(messages(f, f.document.uri));
    parity(next);
  });

  test('alias/autoloadコンテキストの変化を再診断へ反映する', () => {
    const f = fixture();
    const alias = update(f, "alias greet='print value'\n" + original);
    expect(alias.diagnostics.context).not.toBe(f.diagnostics.context);
    expect(alias.diagnostics.files.get(f.document.uri)).not.toBe(f.diagnostics.files.get(f.document.uri));
    expect(messages(alias, f.document.uri)).toEqual([]);
    parity(alias);
    const unknown = fixture('greet() { : }\n', 'cache_future_autoload\n');
    const autoload = update(unknown, 'autoload -Uz cache_future_autoload\ngreet() { : }\n');
    expect(messages(unknown, unknown.document.uri)).toContain('cache_future_autoload is not defined in the project or shell environment.');
    expect(messages(autoload, unknown.document.uri)).toEqual([]);
    parity(autoload);
  });

  test('実行環境が変われば同一targetsでも再診断する', () => {
    const f = fixture('', 'cache_unknown_command\n');
    const next = refreshDiagnosticSnapshot({ snapshot: f.snapshot, environment: emptyShellEnvironment(), previous: f.diagnostics });
    expect(next.files.get(f.document.uri)).not.toBe(f.diagnostics.files.get(f.document.uri));
    expect(next.files.get(f.document.uri)?.items).toEqual([]);
  });

  test('引数仕様を変えて元に戻してもfresh結果と一致し、過去targetsを保持しない', () => {
    const f = fixture();
    const changed = update(f, original.replace('$2: second', '$2?: second'));
    const restored = update(f, original, changed, 2);
    expect(messages(restored, f.document.uri)).toEqual(messages(f, f.document.uri));
    expect(restored.diagnostics.targets).toBe(restored.snapshot.targets);
    expect(restored.diagnostics.targets).not.toBe(f.snapshot.targets);
    parity(changed);
    parity(restored);
  });
});
