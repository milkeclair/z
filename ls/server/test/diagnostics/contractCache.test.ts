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

function createDiagnosticProject(definitions = original, caller = 'greet one\n') {
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

type DiagnosticState = {
  readonly snapshot: FunctionSnapshot;
  readonly diagnostics: DiagnosticSnapshot;
};

function refreshDefinition(
  project: ReturnType<typeof createDiagnosticProject>,
  text: string,
  previous: DiagnosticState = project,
  version = 1,
): DiagnosticState {
  const changed = TextDocument.create(project.uri, 'shellscript', version, text);
  const snapshot = refreshFunctionSnapshot({
    projectRoot: project.root,
    documents: [project.document, changed],
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

function parity(state: DiagnosticState): void {
  const fresh = refreshDiagnosticSnapshot({
    snapshot: state.snapshot,
    environment: environmentReference.read(),
  });

  expect([...state.diagnostics.files.keys()]).toEqual([...fresh.files.keys()]);

  for (const [uri, report] of state.diagnostics.files) {
    expect(report.items).toEqual(fresh.files.get(uri)?.items);
  }
}

function messages(state: DiagnosticState, uri: string): string[] {
  return state.diagnostics.files.get(uri)?.items.map((item) => item.message) ?? [];
}

describe('refreshDiagnosticSnapshot', () => {
  describe('関数の引数仕様を比較する場合', () => {
    test('本文編集で宣言位置が動いても未編集callerを再利用し、変更ファイルの使用状況は更新する', () => {
      const project = createDiagnosticProject();
      const spy = vi.spyOn(calls, 'analyzeCalls');
      const next = refreshDefinition(project, original.replace('print "$1" "$2"', ':'));

      expect(next.snapshot.targets).not.toBe(project.snapshot.targets);
      expect(next.snapshot.targets.get('second')?.[0].nameNode.range.start.offset).not.toBe(
        project.snapshot.targets.get('second')?.[0].nameNode.range.start.offset,
      );
      expect(spy).toHaveBeenCalledTimes(1);
      expect(next.diagnostics.files.get(project.document.uri)).toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      expect(next.diagnostics.targets).toBe(next.snapshot.targets);
      expect(next.diagnostics.files.get(project.uri)?.file).toBe(
        next.snapshot.hydrator.files.get('definitions.zsh'),
      );
      expect(
        next.diagnostics.files
          .get(project.uri)
          ?.items.filter((item) => item.code === 'unused-argument'),
      ).toHaveLength(2);
      parity(next);
    });

    test('説明文と位置の変更をhover/定義へ反映しながらcaller診断を再利用する', () => {
      const project = createDiagnosticProject();
      const next = refreshDefinition(
        project,
        original.replace('# Original docs', '# Edited documentation\n# Additional explanation'),
      );

      expect(next.diagnostics.files.get(project.document.uri)).toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      const documents = {
        get: (uri: string) => (uri === project.document.uri ? project.document : undefined),
      };
      const params = {
        textDocument: { uri: project.document.uri },
        position: { line: 0, character: 2 },
      };

      const hover = zHover({ params, documents, snapshot: next.snapshot });

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Edited documentation') },
      });
      const definition = zDefinition({ params, documents, snapshot: next.snapshot });

      expect(definition?.range.start.line).toBe(4);
      parity(next);
    });

    test('位置番号の変更で呼び出し元を再診断する', () => {
      const before = '# $1: first\ngreet() { print "$1" }\n';
      const after = '# $2: second\ngreet() { print "$2" }\n';
      const caller = 'greet one\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('必須から任意への変更で呼び出し元を再診断する', () => {
      const before = '# $2: second\ngreet() { print "$2" }\n';
      const after = '# $2?: second\ngreet() { print "$2" }\n';
      const caller = 'greet one\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('名前付き引数名の変更で呼び出し元を再診断する', () => {
      const before = '# $option: value\ngreet() { print "$option" }\n';
      const after = '# $other: value\ngreet() { print "$other" }\n';
      const caller = 'greet option=value\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('引数種類の変更で呼び出し元を再診断する', () => {
      const before = '# $1: first\ngreet() { print "$1" }\n';
      const after = '# $option: value\ngreet() { print "$option" }\n';
      const caller = 'greet one\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('可変長引数の変更で呼び出し元を再診断する', () => {
      const before = '# $@: all\ngreet() { print "$@" }\n';
      const after = '# $*: all\ngreet() { print "$*" }\n';
      const caller = 'greet\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('引数宣言の順序変更で呼び出し元を再診断する', () => {
      const before = '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n';
      const after = '# $2: second\n# $1: first\ngreet() { print "$1" "$2" }\n';
      const caller = 'greet\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('関数名の変更で呼び出し元を再診断する', () => {
      const before = 'greet() { : }\n';
      const after = 'renamed() { : }\n';
      const caller = 'greet\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('関数の追加で呼び出し元を再診断する', () => {
      const before = '';
      const after = 'greet() { : }\n';
      const caller = 'greet\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('関数の削除で呼び出し元を再診断する', () => {
      const before = 'greet() { : }\n';
      const after = '';
      const caller = 'greet\n';

      const project = createDiagnosticProject(before, caller);
      const next = refreshDefinition(project, after);

      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.diagnostics.files.get(project.document.uri)?.resultId).not.toBe(
        project.diagnostics.files.get(project.document.uri)?.resultId,
      );
      parity(next);
    });

    test('同名定義の順序変更で解決先の引数仕様を再評価する', () => {
      const first = '# $1: first\ngreet() { print "$1" }\n';
      const second = '# $2: second\ngreet() { print "$2" }\n';
      const project = createDiagnosticProject(first + second);

      expect(messages(project, project.document.uri)).toEqual([]);
      const next = refreshDefinition(project, second + first);

      expect(messages(next, project.document.uri)).toContain('Missing required argument(s): $2');
      parity(next);
    });

    test('定義ファイルの移動でグローバル候補が変わる場合を検出する', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('# $1: first\ngreet() { print "$1" }\n');
      fs.writeFileSync(
        path.join(project.root, 'later.zsh'),
        '# $2: second\ngreet() { print "$2" }\n',
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.document],
        previous: project.snapshot,
      });
      const diagnostics = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });
      fs.renameSync(project.filename, path.join(project.root, 'z-last.zsh'));
      const movedSnapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.document],
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

      expect(messages(moved, project.document.uri)).toContain('Missing required argument(s): $2');
      parity(moved);
    });

    test('引数仕様が同じでも候補URIの変更では再診断する', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject();
      fs.renameSync(project.filename, path.join(project.root, 'moved.zsh'));
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.document],
        previous: project.snapshot,
      });
      const next = {
        snapshot,
        diagnostics: refreshDiagnosticSnapshot({
          snapshot,
          environment,
          previous: project.diagnostics,
        }),
      };

      expect(snapshot.targets.get('greet')?.[0].uri).not.toBe(
        project.snapshot.targets.get('greet')?.[0].uri,
      );
      expect(next.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(messages(next, project.document.uri)).toEqual(messages(project, project.document.uri));
      parity(next);
    });

    test('alias/autoloadコンテキストの変化を再診断へ反映する', () => {
      const project = createDiagnosticProject();
      const alias = refreshDefinition(project, "alias greet='print value'\n" + original);

      expect(alias.diagnostics.context).not.toBe(project.diagnostics.context);
      expect(alias.diagnostics.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(messages(alias, project.document.uri)).toEqual([]);
      parity(alias);
      const unknown = createDiagnosticProject('greet() { : }\n', 'cache_future_autoload\n');
      const autoload = refreshDefinition(
        unknown,
        'autoload -Uz cache_future_autoload\ngreet() { : }\n',
      );

      expect(messages(unknown, unknown.document.uri)).toContain(
        'cache_future_autoload is not defined in the project or shell environment.',
      );
      expect(messages(autoload, unknown.document.uri)).toEqual([]);
      parity(autoload);
    });

    test('実行環境が変われば同一targetsでも再診断する', () => {
      const project = createDiagnosticProject('', 'cache_unknown_command\n');
      const next = refreshDiagnosticSnapshot({
        snapshot: project.snapshot,
        environment: emptyShellEnvironment(),
        previous: project.diagnostics,
      });

      expect(next.files.get(project.document.uri)).not.toBe(
        project.diagnostics.files.get(project.document.uri),
      );
      expect(next.files.get(project.document.uri)?.items).toEqual([]);
    });

    test('引数仕様を変えて元に戻してもfresh結果と一致し、過去targetsを保持しない', () => {
      const project = createDiagnosticProject();
      const changed = refreshDefinition(project, original.replace('$2: second', '$2?: second'));
      const restored = refreshDefinition(project, original, changed, 2);

      expect(messages(restored, project.document.uri)).toEqual(
        messages(project, project.document.uri),
      );
      expect(restored.diagnostics.targets).toBe(restored.snapshot.targets);
      expect(restored.diagnostics.targets).not.toBe(project.snapshot.targets);
      parity(changed);
      parity(restored);
    });
  });
});
