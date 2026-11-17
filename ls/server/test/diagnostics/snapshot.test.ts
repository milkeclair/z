import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { emptyShellEnvironment, readShellEnvironment } from '../../src/diagnostics/environment';
import * as facts from '../../src/diagnostics/facts';
import { validateTextDocument } from '../../src/diagnostics/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { workspaceDiagnostics } from '../../src/diagnostics/workspace';
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

describe('refreshDiagnosticSnapshot', () => {
  describe('制御コメントと診断キャッシュを利用する場合', () => {
    test('制御コメントをhydrationから取得し、文字列やexampleのignoreを適用しない', () => {
      const project2 = createDiagnosticProject('greet # zls: ignore\n');

      const diagnostics2 = validateTextDocument(project2);

      expect(semantic(diagnostics2)).toEqual([]);
      const project3 = createDiagnosticProject('greet # zls: ignore missing-positional-argument\n');

      const diagnostics3 = validateTextDocument(project3);

      expect(semantic(diagnostics3)).toEqual([]);
      const project4 = createDiagnosticProject('greet "# zls: ignore"\n');

      const diagnostics4 = validateTextDocument(project4);

      expect(semantic(diagnostics4)).toHaveLength(1);
      const project5 = createDiagnosticProject('greet # zls: ignored\n');

      const diagnostics5 = validateTextDocument(project5);

      expect(semantic(diagnostics5)).toHaveLength(1);
      const project = createDiagnosticProject('# example:\n#   zls: ignore\ngreet() { : }\n', '');

      expect(project.diagnostics.files.get(project.textDocument.uri)?.items).toEqual([]);
    });

    test('変更のない解析結果を再利用し、呼び出し編集では他ファイルを再走査しない', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('greet one two\n');
      const spy = vi.spyOn(facts, 'collectFileFacts');

      expect(
        refreshDiagnosticSnapshot({
          snapshot: project.snapshot,
          environment,
          previous: project.diagnostics,
        }),
      ).toBe(project.diagnostics);
      const changed = TextDocument.create(
        project.textDocument.uri,
        'shellscript',
        2,
        'greet one\n',
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [changed],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      expect(spy).toHaveBeenCalledTimes(1);
      expect(next.files.get(project.definitionUri)).toBe(
        project.diagnostics.files.get(project.definitionUri),
      );
      const diagnostics2 = validateTextDocument({ diagnostics: next, textDocument: changed });

      expect(semantic(diagnostics2)).toHaveLength(1);
      const diagnostics3 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(diagnostics3).toEqual([]);
    });

    test('workspace外のaliasはその文書へ適用し、projectへ混ぜない', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('fixture-outside-alias\n');
      const outside = TextDocument.create(
        pathToFileURL(path.join(path.dirname(project.root), 'outside.zsh')).href,
        'shellscript',
        1,
        "alias fixture-outside-alias='print x'\nfixture-outside-alias\n",
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, outside],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      const diagnostics2 = validateTextDocument({ diagnostics: next, textDocument: outside });

      expect(semantic(diagnostics2)).toEqual([]);
      const diagnostics3 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics3)).toHaveLength(1);
      expect(
        workspaceDiagnostics({ diagnostics: next }).items.some((item) => item.uri === outside.uri),
      ).toBe(false);
    });

    test('module読み込みの追加・削除で未編集の呼び出しも再評価する', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('zpty\n', 'zmodload zsh/zpty\n');

      const diagnostics2 = validateTextDocument(project);

      expect(semantic(diagnostics2)).toEqual([]);
      const changed = TextDocument.create(project.definitionUri, 'shellscript', 1, '');
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, changed],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      expect(next.files.get(project.textDocument.uri)?.facts).toBe(
        project.diagnostics.files.get(project.textDocument.uri)?.facts,
      );
      const diagnostics3 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics3)).toMatchObject([{ code: 'undefined-command' }]);
      const restored = TextDocument.create(
        project.definitionUri,
        'shellscript',
        2,
        'zmodload zsh/zpty\n',
      );
      const restoredSnapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, restored],
        previous: snapshot,
      });
      const checked = refreshDiagnosticSnapshot({
        snapshot: restoredSnapshot,
        environment,
        previous: next,
      });

      const diagnostics4 = validateTextDocument({
        diagnostics: checked,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics4)).toEqual([]);
    });

    test('workspace外のmodule読み込みはその文書だけへ適用する', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('zpty\n', '');
      const outside = TextDocument.create(
        pathToFileURL(path.join(path.dirname(project.root), 'module-outside.zsh')).href,
        'shellscript',
        1,
        'zmodload zsh/zpty\nzpty\n',
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, outside],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({ snapshot, environment });

      const diagnostics2 = validateTextDocument({ diagnostics: next, textDocument: outside });

      expect(semantic(diagnostics2)).toEqual([]);
      const diagnostics3 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics3)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('workspace外の関数はその文書の診断に使い、projectへ混ぜない', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('fixture-outside-function\n');
      const outside = TextDocument.create(
        pathToFileURL(path.join(path.dirname(project.root), 'outside.zsh')).href,
        'shellscript',
        1,
        '# $1: value\nfixture-outside-function() { print "$1" }\nfixture-outside-function\n',
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, outside],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({ snapshot, environment });

      const diagnostics2 = validateTextDocument({ diagnostics: next, textDocument: outside });

      expect(semantic(diagnostics2)).toMatchObject([{ code: 'missing-positional-argument' }]);
      const diagnostics3 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics3)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('calleeのドキュメント変更で未編集の呼び出しを再評価する', () => {
      const environment = environmentReference.read();

      const project = createDiagnosticProject('greet one two\n');
      const changed = TextDocument.create(
        project.definitionUri,
        'shellscript',
        1,
        '# $3: third\ngreet() { print "$3" }\n',
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, changed],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      expect(next.files.get(project.textDocument.uri)?.facts).toBe(
        project.diagnostics.files.get(project.textDocument.uri)?.facts,
      );
      const diagnostics2 = validateTextDocument({
        diagnostics: next,
        textDocument: project.textDocument,
      });

      expect(semantic(diagnostics2)).toHaveLength(1);
    });

    test('workspaceレポートはopen versionと未保存ファイルを含み、削除済みの結果を空にする', () => {
      const project = createDiagnosticProject('greet one\n');
      const report = workspaceDiagnostics({
        diagnostics: project.diagnostics,
        previousResultIds: [{ uri: 'file:///removed.zsh', value: 'old' }],
      });

      expect(report.items.find((item) => item.uri === project.textDocument.uri)).toMatchObject({
        version: 1,
        resultId: expect.any(String),
        items: expect.any(Array),
      });
      expect(report.items.find((item) => item.uri === project.definitionUri)?.version).toBeNull();
      expect(report.items.find((item) => item.uri === 'file:///removed.zsh')?.items).toEqual([]);
    });

    test('CRLFの書式診断は改行を含まないLSP範囲を返す', () => {
      const project = createDiagnosticProject(' \r\nprint x\r\n');

      const diagnostics = validateTextDocument(project);

      expect(diagnostics.find((item) => item.code === 'empty-line')?.range.end).toEqual({
        line: 0,
        character: 1,
      });
    });

    test('構文・文書診断を分けて返し、書式診断をliteral内部へ適用しない', () => {
      const project = createDiagnosticProject('print "unfinished\n');

      const diagnostics = validateTextDocument(project);

      expect(diagnostics.some((item) => item.source === 'z-ls/lexer')).toBe(true);
      const project2 = createDiagnosticProject('if true; then\n');

      const diagnostics2 = validateTextDocument(project2);

      expect(diagnostics2.some((item) => item.source === 'z-ls/parser')).toBe(true);
      const project3 = createDiagnosticProject('print "a\n  \nb"\n');

      const diagnostics3 = validateTextDocument(project3);

      expect(diagnostics3.filter((item) => item.code === 'empty-line')).toEqual([]);
      const last = validateTextDocument(createDiagnosticProject('print x\nprint y')).find(
        (item) => item.code === 'final-newline',
      );

      expect(last?.range.start).toEqual({ line: 1, character: 7 });
    });
  });
});
