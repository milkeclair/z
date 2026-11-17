import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { zDefinition } from '../../src/connection/definition';
import { zHover } from '../../src/connection/hover';
import * as calls from '../../src/diagnostics/calls';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { emptyShellEnvironment, readShellEnvironment } from '../../src/diagnostics/environment';
import type { DiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import type { FunctionSnapshot } from '../../src/refreshFunctions/main';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { createIOState } from '../../src/util/ioState';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();
const shellRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-contract-shell-'));
const environmentReference = createIOState<ShellEnvironment>(emptyShellEnvironment());
beforeAll(async () => {
  fs.writeFileSync(path.join(shellRoot, '.zshrc'), '');
  environmentReference.replace(
    await readShellEnvironment({ env: { ...process.env, ZDOTDIR: shellRoot } }),
  );
  expect(environmentReference.read().kind).toBe('available');
});
afterAll(() => fs.rmSync(shellRoot, { recursive: true, force: true }));
afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
});
const original =
  '# Original docs\n# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\nsecond() { : }\n';
function createDiagnosticFixture(definitions = original, caller = 'greet one\n') {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-contract-cache-'));
  temporaryDirectories.track(root);
  const filename = path.join(root, 'definitions.zsh');
  fs.writeFileSync(filename, definitions);
  const uri = pathToFileURL(filename).href;
  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    caller,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({
    snapshot,
    environment: environmentReference.read(),
  });
  return { root, filename, uri, document, snapshot, diagnostics };
}
type State = { readonly snapshot: FunctionSnapshot; readonly diagnostics: DiagnosticSnapshot };
function update(
  f: ReturnType<typeof createDiagnosticFixture>,
  text: string,
  previous: State = f,
  version = 1,
): State {
  const changed = TextDocument.create(f.uri, 'shellscript', version, text);
  const snapshot = refreshFunctionSnapshot({
    projectRoot: f.root,
    documents: [f.document, changed],
    previous: previous.snapshot,
  });
  return {
    snapshot,
    diagnostics: refreshDiagnosticSnapshot({
      snapshot,
      environment: environmentReference.read(),
      previous: previous.diagnostics,
    }),
  };
}
function parity(state: State): void {
  const fresh = refreshDiagnosticSnapshot({
    snapshot: state.snapshot,
    environment: environmentReference.read(),
  });
  expect([...state.diagnostics.files.keys()]).toEqual([...fresh.files.keys()]);
  for (const [uri, report] of state.diagnostics.files) {
    expect(report.items).toEqual(fresh.files.get(uri)?.items);
  }
}
function messages(state: State, uri: string): string[] {
  return state.diagnostics.files.get(uri)?.items.map((item) => item.message) ?? [];
}

describe('diagnostic call contract cache', () => {
  test('本文編集で宣言位置が動いても未編集callerを再利用し、変更ファイルの使用状況は更新する', () => {
    const scenario = createDiagnosticFixture();
    const spy = vi.spyOn(calls, 'analyzeCalls');
    const next = update(scenario, original.replace('print "$1" "$2"', ':'));
    expect(next.snapshot.targets).not.toBe(scenario.snapshot.targets);
    expect(next.snapshot.targets.get('second')?.[0].nameNode.range.start.offset).not.toBe(
      scenario.snapshot.targets.get('second')?.[0].nameNode.range.start.offset,
    );
    expect(spy).toHaveBeenCalledTimes(1);
    expect(next.diagnostics.files.get(scenario.document.uri)).toBe(
      scenario.diagnostics.files.get(scenario.document.uri),
    );
    expect(next.diagnostics.files.get(scenario.document.uri)?.resultId).toBe(
      scenario.diagnostics.files.get(scenario.document.uri)?.resultId,
    );
    expect(next.diagnostics.targets).toBe(next.snapshot.targets);
    expect(next.diagnostics.files.get(scenario.uri)?.file).toBe(
      next.snapshot.hydrator.files.get('definitions.zsh'),
    );
    expect(
      next.diagnostics.files
        .get(scenario.uri)
        ?.items.filter((item) => item.code === 'unused-argument'),
    ).toHaveLength(2);
    parity(next);
  });

  test('説明文と位置の変更をhover/定義へ反映しながらcaller診断を再利用する', () => {
    const scenario = createDiagnosticFixture();
    const next = update(
      scenario,
      original.replace('# Original docs', '# Edited documentation\n# Additional explanation'),
    );
    expect(next.diagnostics.files.get(scenario.document.uri)).toBe(
      scenario.diagnostics.files.get(scenario.document.uri),
    );
    const documents = {
      get: (uri: string) => (uri === scenario.document.uri ? scenario.document : undefined),
    };
    const params = {
      textDocument: { uri: scenario.document.uri },
      position: { line: 0, character: 2 },
    };
    expect(zHover({ params, documents, snapshot: next.snapshot })).toMatchObject({
      contents: { value: expect.stringContaining('Edited documentation') },
    });
    expect(zDefinition({ params, documents, snapshot: next.snapshot })?.range.start.line).toBe(4);
    parity(next);
  });

  test.each([
    [
      '位置番号',
      '# $1: first\ngreet() { print "$1" }\n',
      '# $2: second\ngreet() { print "$2" }\n',
      'greet one\n',
    ],
    [
      '必須から任意',
      '# $2: second\ngreet() { print "$2" }\n',
      '# $2?: second\ngreet() { print "$2" }\n',
      'greet one\n',
    ],
    [
      '名前付き引数',
      '# $option: value\ngreet() { print "$option" }\n',
      '# $other: value\ngreet() { print "$other" }\n',
      'greet option=value\n',
    ],
    [
      '引数種類',
      '# $1: first\ngreet() { print "$1" }\n',
      '# $option: value\ngreet() { print "$option" }\n',
      'greet one\n',
    ],
    [
      '残余引数',
      '# $@: all\ngreet() { print "$@" }\n',
      '# $*: all\ngreet() { print "$*" }\n',
      'greet\n',
    ],
    [
      '引数の元の順序',
      '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n',
      '# $2: second\n# $1: first\ngreet() { print "$1" "$2" }\n',
      'greet\n',
    ],
    ['関数名', 'greet() { : }\n', 'renamed() { : }\n', 'greet\n'],
    ['関数追加', '', 'greet() { : }\n', 'greet\n'],
    ['関数削除', 'greet() { : }\n', '', 'greet\n'],
  ])('%sの変更ではcallerを再診断する', (_, before, after, caller) => {
    const scenario = createDiagnosticFixture(before, caller);
    const next = update(scenario, after);
    expect(next.diagnostics.files.get(scenario.document.uri)).not.toBe(
      scenario.diagnostics.files.get(scenario.document.uri),
    );
    expect(next.diagnostics.files.get(scenario.document.uri)?.resultId).not.toBe(
      scenario.diagnostics.files.get(scenario.document.uri)?.resultId,
    );
    parity(next);
  });

  test('同名定義の順序変更で解決先の引数仕様を再評価する', () => {
    const first = '# $1: first\ngreet() { print "$1" }\n';
    const second = '# $2: second\ngreet() { print "$2" }\n';
    const scenario = createDiagnosticFixture(first + second);
    expect(messages(scenario, scenario.document.uri)).toEqual([]);
    const next = update(scenario, second + first);
    expect(messages(next, scenario.document.uri)).toContain('Missing required argument(s): $2');
    parity(next);
  });

  test('定義ファイルの移動でグローバル候補が変わる場合を検出する', () => {
    const environment = environmentReference.read();

    const scenario = createDiagnosticFixture('# $1: first\ngreet() { print "$1" }\n');
    fs.writeFileSync(
      path.join(scenario.root, 'later.zsh'),
      '# $2: second\ngreet() { print "$2" }\n',
    );
    const snapshot = refreshFunctionSnapshot({
      projectRoot: scenario.root,
      documents: [scenario.document],
      previous: scenario.snapshot,
    });
    const diagnostics = refreshDiagnosticSnapshot({
      snapshot,
      environment,
      previous: scenario.diagnostics,
    });
    fs.renameSync(scenario.filename, path.join(scenario.root, 'z-last.zsh'));
    const movedSnapshot = refreshFunctionSnapshot({
      projectRoot: scenario.root,
      documents: [scenario.document],
      previous: snapshot,
    });
    const moved = {
      snapshot: movedSnapshot,
      diagnostics: refreshDiagnosticSnapshot({
        snapshot: movedSnapshot,
        environment,
        previous: diagnostics,
      }),
    };
    expect(messages(moved, scenario.document.uri)).toContain('Missing required argument(s): $2');
    parity(moved);
  });

  test('引数仕様が同じでも候補URIの変更では再診断する', () => {
    const environment = environmentReference.read();

    const scenario = createDiagnosticFixture();
    fs.renameSync(scenario.filename, path.join(scenario.root, 'moved.zsh'));
    const snapshot = refreshFunctionSnapshot({
      projectRoot: scenario.root,
      documents: [scenario.document],
      previous: scenario.snapshot,
    });
    const next = {
      snapshot,
      diagnostics: refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: scenario.diagnostics,
      }),
    };
    expect(snapshot.targets.get('greet')?.[0].uri).not.toBe(
      scenario.snapshot.targets.get('greet')?.[0].uri,
    );
    expect(next.diagnostics.files.get(scenario.document.uri)).not.toBe(
      scenario.diagnostics.files.get(scenario.document.uri),
    );
    expect(messages(next, scenario.document.uri)).toEqual(
      messages(scenario, scenario.document.uri),
    );
    parity(next);
  });

  test('alias/autoloadコンテキストの変化を再診断へ反映する', () => {
    const scenario = createDiagnosticFixture();
    const alias = update(scenario, "alias greet='print value'\n" + original);
    expect(alias.diagnostics.context).not.toBe(scenario.diagnostics.context);
    expect(alias.diagnostics.files.get(scenario.document.uri)).not.toBe(
      scenario.diagnostics.files.get(scenario.document.uri),
    );
    expect(messages(alias, scenario.document.uri)).toEqual([]);
    parity(alias);
    const unknown = createDiagnosticFixture('greet() { : }\n', 'cache_future_autoload\n');
    const autoload = update(unknown, 'autoload -Uz cache_future_autoload\ngreet() { : }\n');
    expect(messages(unknown, unknown.document.uri)).toContain(
      'cache_future_autoload is not defined in the project or shell environment.',
    );
    expect(messages(autoload, unknown.document.uri)).toEqual([]);
    parity(autoload);
  });

  test('実行環境が変われば同一targetsでも再診断する', () => {
    const scenario = createDiagnosticFixture('', 'cache_unknown_command\n');
    const next = refreshDiagnosticSnapshot({
      snapshot: scenario.snapshot,
      environment: emptyShellEnvironment(),
      previous: scenario.diagnostics,
    });
    expect(next.files.get(scenario.document.uri)).not.toBe(
      scenario.diagnostics.files.get(scenario.document.uri),
    );
    expect(next.files.get(scenario.document.uri)?.items).toEqual([]);
  });

  test('引数仕様を変えて元に戻してもfresh結果と一致し、過去targetsを保持しない', () => {
    const scenario = createDiagnosticFixture();
    const changed = update(scenario, original.replace('$2: second', '$2?: second'));
    const restored = update(scenario, original, changed, 2);
    expect(messages(restored, scenario.document.uri)).toEqual(
      messages(scenario, scenario.document.uri),
    );
    expect(restored.diagnostics.targets).toBe(restored.snapshot.targets);
    expect(restored.diagnostics.targets).not.toBe(scenario.snapshot.targets);
    parity(changed);
    parity(restored);
  });
});
