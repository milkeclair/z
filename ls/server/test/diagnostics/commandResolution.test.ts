import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { emptyShellEnvironment, readShellEnvironment } from '../../src/diagnostics/environment';
import { validateTextDocument } from '../../src/diagnostics/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { createIOState } from '../../src/util/ioState';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

const environmentRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-diag-shell-'));

const environmentReference = createIOState<ShellEnvironment>(emptyShellEnvironment());

beforeAll(async () => {
  fs.writeFileSync(
    path.join(environmentRoot, '.zshrc'),
    [
      "alias fixture-shell-alias='print value'",
      "alias -g FIXTURE_GLOBAL='one two'",
      'alias -s fixture_suffix=cat',
      'fixture-shell-function() { : }',
      'autoload -Uz fixture-shell-autoload',
    ].join('\n'),
  );
  environmentReference.replace(
    await readShellEnvironment({ env: { ...process.env, ZDOTDIR: environmentRoot } }),
  );

  expect(environmentReference.read().kind).toBe('available');
});

afterAll(() => fs.rmSync(environmentRoot, { recursive: true, force: true }));

afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
});

const definition = '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n';

function createDiagnosticProject(
  content: string,
  definitions = definition,
  shell = environmentReference.read(),
) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-diag-'));
  temporaryDirectories.track(root);
  const definitionUri = pathToFileURL(path.join(root, 'definition.zsh')).href;
  fs.writeFileSync(path.join(root, 'definition.zsh'), definitions);
  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    content,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: shell });

  return {
    root,
    snapshot,
    diagnostics,
    textDocument: document,
    definitionUri,
  };
}

const semantic = (items: ReturnType<typeof validateTextDocument>) =>
  items.filter((item) =>
    ['missing-positional-argument', 'missing-named-argument', 'undefined-command'].includes(
      item.code ?? '',
    ),
  );

describe('validateTextDocument', () => {
  describe('コマンド名を解決する場合', () => {
    test('シェルのbuiltinを解決する', () => {
      const source = 'print x\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('外部コマンドを解決する', () => {
      const source = 'env\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('通常のaliasを解決する', () => {
      const source = 'fixture-shell-alias\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('シェル関数を解決する', () => {
      const source = 'fixture-shell-function\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('autoload関数を解決する', () => {
      const source = 'fixture-shell-autoload\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('suffix aliasを解決する', () => {
      const source = 'file.fixture_suffix\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('builtin修飾子の後のコマンドを解決する', () => {
      const source = 'builtin print x\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('commandの照会対象を未定義として診断しない', () => {
      const source = 'command -v fixture-missing-command\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('一般名とz名の未定義コマンドを同じルールで診断する', () => {
      for (const command of ['fixture-missing-command', 'z.fixture.missing']) {
        const project = createDiagnosticProject(command + '\n');

        const diagnostics = validateTextDocument(project);

        expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
      }
    });

    test('projectのalias・global/suffix alias・autoload宣言を解決する', () => {
      for (const source of [
        "alias fixture-local='print x'\nfixture-local\n",
        "alias -g FIXTURE_LOCAL='one two'\ngreet FIXTURE_LOCAL\n",
        'alias -s fixture_local=print\nfile.fixture_local\n',
        'autoload -Uz fixture-local-autoload\nfixture-local-autoload\n',
      ]) {
        const project = createDiagnosticProject(source);

        const diagnostics = validateTextDocument(project);

        expect(semantic(diagnostics)).toEqual([]);
      }
    });

    test('zsh/zptyのzptyを解決する', () => {
      const module = 'zsh/zpty';
      const command = 'zpty';

      const project = createDiagnosticProject('zmodload ' + module + '\n' + command + '\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('zsh/zselectのzselectを解決する', () => {
      const module = 'zsh/zselect';
      const command = 'zselect';

      const project = createDiagnosticProject('zmodload ' + module + '\n' + command + '\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('zsh/systemのsysreadを解決する', () => {
      const module = 'zsh/system';
      const command = 'sysread';

      const project = createDiagnosticProject('zmodload ' + module + '\n' + command + '\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('zsh/systemのzsystemを解決する', () => {
      const module = 'zsh/system';
      const command = 'zsystem';

      const project = createDiagnosticProject('zmodload ' + module + '\n' + command + '\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('zsh/net/tcpのztcpを解決する', () => {
      const module = 'zsh/net/tcp';
      const command = 'ztcp';

      const project = createDiagnosticProject('zmodload ' + module + '\n' + command + '\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('zsh/datetimeのstrftimeを解決する', () => {
      const module = 'zsh/datetime';
      const command = 'strftime';

      const project = createDiagnosticProject('zmodload ' + module + '\n' + command + '\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('読み込み宣言のないmodule builtinは未定義として残す', () => {
      const project = createDiagnosticProject('zpty\nzselect\nsysread\nzsystem\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toHaveLength(4);
    });

    test('アンロード指定を読み込み宣言にしない', () => {
      const option = '-u';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('存在確認を読み込み宣言にしない', () => {
      const option = '-e';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('一覧表示を読み込み宣言にしない', () => {
      const option = '-L';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('依存関係の照会を読み込み宣言にしない', () => {
      const option = '-d';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('feature一覧を読み込み宣言にしない', () => {
      const option = '-Fl';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('featureの有効一覧を読み込み宣言にしない', () => {
      const option = '-FL';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('featureの存在確認を読み込み宣言にしない', () => {
      const option = '-Fe';

      const project = createDiagnosticProject('zmodload ' + option + ' zsh/zpty\nzpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('静的なmodule名とbuiltinのautoload・feature指定を解決する', () => {
      for (const source of [
        'builtin zmodload -is -- "zsh/zpty"\nzpty\n',
        'zmodload -ab fixture/module fixture-module-builtin\nfixture-module-builtin\n',
        'zmodload -Fa fixture/module +b:fixture-module-builtin\nfixture-module-builtin\n',
        'zmodload -F zsh/system b:sysread -b:zsystem\nsysread\n',
      ]) {
        const project = createDiagnosticProject(source);

        const diagnostics = validateTextDocument(project);

        expect(semantic(diagnostics)).toEqual([]);
      }

      for (const source of [
        'zmodload "$module"\nzpty\n',
        'zmodload fixture/unknown\nzpty\n',
        'zmodload -F zsh/system b:sysread -b:zsystem\nzsystem\n',
        'zmodload -F zsh/zpty\nzpty\n',
        'zmodload -F zsh/system b:sysread -b:sysread\nsysread\n',
        'command -v zmodload zsh/zpty\nzpty\n',
        'print zmodload zsh/zpty\nzpty\n',
      ]) {
        const project2 = createDiagnosticProject(source);

        const diagnostics2 = validateTextDocument(project2);

        expect(semantic(diagnostics2)).toMatchObject([{ code: 'undefined-command' }]);
      }
    });

    test('module builtinでもbuiltinとcommandの解決規則を維持する', () => {
      const environment = environmentReference.read();

      const declaration = 'zmodload zsh/zpty\n';

      const project = createDiagnosticProject(declaration + 'builtin zpty\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
      const project2 = createDiagnosticProject(declaration + 'command zpty\n');

      const diagnostics2 = validateTextDocument(project2);

      expect(semantic(diagnostics2)).toMatchObject([{ code: 'undefined-command' }]);

      if (environment.kind !== 'available') {
        throw new Error('shell unavailable');
      }

      const project3 = createDiagnosticProject(declaration + 'command zpty\n', '', {
        ...environment,
        commandBuiltins: true,
      });

      const diagnostics3 = validateTextDocument(project3);

      expect(semantic(diagnostics3)).toEqual([]);
    });

    test('引用されたalias名と明示modifierを区別する', () => {
      const project = createDiagnosticProject("'fixture-shell-alias'\n");

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
      const project2 = createDiagnosticProject('builtin greet\n');

      const diagnostics2 = validateTextDocument(project2);

      expect(semantic(diagnostics2)).toMatchObject([{ code: 'undefined-command' }]);
      const project3 = createDiagnosticProject('command greet\n');

      const diagnostics3 = validateTextDocument(project3);

      expect(semantic(diagnostics3)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('絶対パス・workspaceからの相対パスは実行権限も確認する', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('./tool\n');
      fs.writeFileSync(path.join(project.root, 'tool'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
      const next = refreshDiagnosticSnapshot({ snapshot: project.snapshot, environment });

      const diagnostics2 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics2)).toEqual([]);
      fs.chmodSync(path.join(project.root, 'tool'), 0o644);
      const unavailable = refreshDiagnosticSnapshot({ snapshot: project.snapshot, environment });

      const diagnostics3 = validateTextDocument({
        diagnostics: unavailable,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics3)).toEqual([]);
      const absolute = TextDocument.create(
        project.textDocument.uri,
        'shellscript',
        2,
        path.join(project.root, 'tool') + '\n',
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [absolute],
        previous: project.snapshot,
      });
      const checked = refreshDiagnosticSnapshot({ snapshot, environment });

      const diagnostics4 = validateTextDocument({ diagnostics: checked, textDocument: absolute });

      expect(semantic(diagnostics4)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('動的なcommand wordやcwd依存の相対パスは未定義と断定しない', () => {
      for (const source of [
        './fixture-elsewhere\n',
        '~/bin/fixture-elsewhere\n',
        '=fixture-command\n',
        'fixture-*\n',
      ]) {
        const project = createDiagnosticProject(source);

        const diagnostics = validateTextDocument(project);

        expect(semantic(diagnostics)).toEqual([]);
      }
    });

    test('環境取得失敗時も既知関数の診断を続け、未解決名をエラーと断定しない', () => {
      const project = createDiagnosticProject(
        'greet one\nfixture-unknown\n',
        definition,
        emptyShellEnvironment(),
      );

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
    });
  });
});
