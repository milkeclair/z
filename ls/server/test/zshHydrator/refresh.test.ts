import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import {
  createZshHydrator,
  directivesOf,
  documentationOf,
  refreshZshHydrator,
} from '../../src/zshHydrator';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

function createHydrationFixture(): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-hydrator-test-'));
  temporaryDirectories.track(root);

  return root;
}

afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
});

function document(root: string, name: string, version: number, content: string) {
  return TextDocument.create(
    pathToFileURL(path.join(root, name)).href,
    'shellscript',
    version,
    content,
  );
}

describe('refreshZshHydrator', () => {
  describe('ファイルの読み込みと再利用を行う場合', () => {
    test('stat後にディレクトリへ置き換わったファイルも除外する', () => {
      const root = createHydrationFixture();
      const file = path.join(root, 'sample.zsh');
      fs.writeFileSync(file, 'helper() { : }\n');
      const originalRead = fs.readFileSync;
      const replaceFile = vi.fn(() => {
        fs.unlinkSync(file);
        fs.mkdirSync(file);
      });
      vi.spyOn(fs, 'readFileSync').mockImplementation((...args) => {
        if (args[0] === file && replaceFile.mock.calls.length === 0) {
          replaceFile();
        }

        return originalRead(...args);
      });

      const result = createZshHydrator(root);

      expect(replaceFile).toHaveBeenCalledOnce();
      expect(result.files.size).toBe(0);
    });

    test('読み取り権限などのI/Oエラーを呼び出し元へ返す', () => {
      const root = createHydrationFixture();
      const file = path.join(root, 'sample.zsh');
      fs.writeFileSync(file, 'helper() { : }\n');
      const denied = Object.assign(new Error('permission denied'), { code: 'EACCES' });
      const originalStat = fs.statSync;
      vi.spyOn(fs, 'statSync').mockImplementation((...args) => {
        if (args[0] === file) {
          throw denied;
        }

        return originalStat(...args);
      });

      expect(() => createZshHydrator(root)).toThrow(denied);
    });

    test('走査中に削除されたファイルを除外する', () => {
      const root = createHydrationFixture();

      const firstFile = path.join(root, 'a.zsh');
      const parent = root;

      const removedFile = path.join(parent, 'b.zsh');
      fs.writeFileSync(firstFile, 'first() { : }\n');
      fs.writeFileSync(removedFile, 'removed() { : }\n');
      const originalStat = fs.statSync;
      const removeFile = vi.fn(() => {
        fs.unlinkSync(removedFile);
      });
      vi.spyOn(fs, 'statSync').mockImplementation((...args) => {
        if (args[0] === firstFile && removeFile.mock.calls.length === 0) {
          removeFile();
        }

        return originalStat(...args);
      });

      const result = createZshHydrator(root);

      expect(removeFile).toHaveBeenCalledOnce();
      expect([...result.files.keys()]).toEqual(['a.zsh']);
      expect(result.files.get('a.zsh')?.functions[0].name).toBe('first');
    });

    test('走査中に親がファイルへ置換された項目を除外する', () => {
      const root = createHydrationFixture();

      const firstFile = path.join(root, 'a.zsh');
      const parent = path.join(root, 'directory');

      fs.mkdirSync(parent);

      const removedFile = path.join(parent, 'b.zsh');
      fs.writeFileSync(firstFile, 'first() { : }\n');
      fs.writeFileSync(removedFile, 'removed() { : }\n');
      const originalStat = fs.statSync;
      const removeFile = vi.fn(() => {
        fs.unlinkSync(removedFile);
        fs.rmdirSync(parent);
        fs.writeFileSync(parent, 'replaced');
      });
      vi.spyOn(fs, 'statSync').mockImplementation((...args) => {
        if (args[0] === firstFile && removeFile.mock.calls.length === 0) {
          removeFile();
        }

        return originalStat(...args);
      });

      const result = createZshHydrator(root);

      expect(removeFile).toHaveBeenCalledOnce();
      expect([...result.files.keys()]).toEqual(['a.zsh']);
      expect(result.files.get('a.zsh')?.functions[0].name).toBe('first');
    });

    test('走査中にディレクトリへ置換された項目を除外する', () => {
      const root = createHydrationFixture();

      const firstFile = path.join(root, 'a.zsh');
      const parent = root;

      const removedFile = path.join(parent, 'b.zsh');
      fs.writeFileSync(firstFile, 'first() { : }\n');
      fs.writeFileSync(removedFile, 'removed() { : }\n');
      const originalStat = fs.statSync;
      const removeFile = vi.fn(() => {
        fs.unlinkSync(removedFile);
        fs.mkdirSync(removedFile);
      });
      vi.spyOn(fs, 'statSync').mockImplementation((...args) => {
        if (args[0] === firstFile && removeFile.mock.calls.length === 0) {
          removeFile();
        }

        return originalStat(...args);
      });

      const result = createZshHydrator(root);

      expect(removeFile).toHaveBeenCalledOnce();
      expect([...result.files.keys()]).toEqual(['a.zsh']);
      expect(result.files.get('a.zsh')?.functions[0].name).toBe('first');
    });

    test('同じversionと長さで開き直した文書も内容が変われば再解析する', () => {
      const root = createHydrationFixture();
      const first = refreshZshHydrator({
        previous: createZshHydrator(root),
        projectRoot: root,
        documents: [document(root, 'sample.zsh', 1, 'first() { : }\n')],
      });
      const next = refreshZshHydrator({
        previous: first,
        projectRoot: root,
        documents: [document(root, 'sample.zsh', 1, 'other() { : }\n')],
      });

      expect(next.files.get('sample.zsh')?.functions[0].name).toBe('other');
      expect(next.files.get('sample.zsh')).not.toBe(first.files.get('sample.zsh'));
      expect(first.files.get('sample.zsh')?.functions[0].name).toBe('first');
      const unchanged = refreshZshHydrator({
        previous: next,
        projectRoot: root,
        documents: [document(root, 'sample.zsh', 1, 'other() { : }\n')],
      });

      expect(unchanged.files.get('sample.zsh')).toBe(next.files.get('sample.zsh'));
    });

    test('project未選択の空状態でも解釈設定を次のrefreshへ引き継ぐ', () => {
      const root = createHydrationFixture();
      fs.writeFileSync(path.join(root, 'sample.zsh'), 'helper() { : } # custom: ignore\n');
      const empty = createZshHydrator('', { directiveNamespaces: ['custom'] });

      expect(empty.options.directiveNamespaces).toEqual(['custom']);
      const next = refreshZshHydrator({ previous: empty, projectRoot: root, documents: [] });

      expect(next.files.get('sample.zsh')?.ast.comments.flatMap(directivesOf)).toHaveLength(1);
    });

    test('隠しファイルと隠しディレクトリ内のdisk文書も読み込む', () => {
      const root = createHydrationFixture();
      fs.mkdirSync(path.join(root, '.config'));
      fs.mkdirSync(path.join(root, '.git'));
      fs.mkdirSync(path.join(root, '.config', '.git'));
      fs.mkdirSync(path.join(root, 'node_modules'));
      fs.writeFileSync(path.join(root, '.hidden.zsh'), 'hidden() { : }\n');
      fs.writeFileSync(path.join(root, '.config', 'sample.zsh'), 'configured() { : }\n');
      fs.writeFileSync(
        path.join(root, '.config', '.git', 'ignored.zsh'),
        'nested_git_ignored() { : }\n',
      );
      fs.writeFileSync(path.join(root, '.git', 'ignored.zsh'), 'git_ignored() { : }\n');
      fs.writeFileSync(
        path.join(root, 'node_modules', 'ignored.zsh'),
        'dependency_ignored() { : }\n',
      );

      expect([...createZshHydrator(root).files.keys()].toSorted()).toEqual([
        '.config/sample.zsh',
        '.hidden.zsh',
      ]);
    });

    test('同じsizeとmtimeに戻したdiskの編集も再解析する', () => {
      const root = createHydrationFixture();
      const file = path.join(root, 'sample.zsh');
      fs.writeFileSync(file, 'first() { : }\n');
      fs.utimesSync(file, 1700000000, 1700000000);
      const first = createZshHydrator(root);
      const stat = fs.statSync(file);
      fs.writeFileSync(file, 'other() { : }\n');
      fs.utimesSync(file, stat.atime, stat.mtime);

      expect(fs.statSync(file).mtimeMs).toBe(stat.mtimeMs);
      expect(fs.statSync(file).size).toBe(stat.size);
      const next = refreshZshHydrator({ previous: first, projectRoot: root, documents: [] });

      expect(next.files.get('sample.zsh')?.functions[0].name).toBe('other');
      expect(next.files.get('sample.zsh')).not.toBe(first.files.get('sample.zsh'));
    });

    test('変更のないdiskファイルのASTを再利用し、削除ファイルを除去する', () => {
      const root = createHydrationFixture();
      fs.writeFileSync(path.join(root, 'sample.zsh'), '# $1: disk\nhelper() { : }\n');
      const first = createZshHydrator(root);
      const again = refreshZshHydrator({ previous: first, projectRoot: root, documents: [] });

      expect(again.files.get('sample.zsh')).toBe(first.files.get('sample.zsh'));
      fs.unlinkSync(path.join(root, 'sample.zsh'));
      const removed = refreshZshHydrator({ previous: again, projectRoot: root, documents: [] });

      expect(removed.files.size).toBe(0);
      expect(first.files.size).toBe(1);
    });

    test('未保存テキストを優先し、版変更で古い付加情報を置き換える', () => {
      const root = createHydrationFixture();
      fs.writeFileSync(path.join(root, 'sample.zsh'), '# $1: disk\nhelper() { : }\n');
      const first = createZshHydrator(root);
      const opened = document(
        root,
        'sample.zsh',
        1,
        '# $name?: unsaved\nhelper() { : } # zls: ignore\n',
      );
      const live = refreshZshHydrator({ previous: first, projectRoot: root, documents: [opened] });
      const entry = live.files.get('sample.zsh');

      expect(entry).toBeDefined();

      if (!entry) {
        throw new Error('entry required');
      }

      expect(documentationOf(entry.functions[0].definition)?.parameters).toMatchObject([
        { kind: 'namedParameterDoc', name: 'name', optional: true },
      ]);
      expect(entry.ast.comments.map(directivesOf).flat()).toHaveLength(1);
      expect(
        refreshZshHydrator({ previous: live, projectRoot: root, documents: [opened] }).files.get(
          'sample.zsh',
        ),
      ).toBe(entry);
      const edited = document(root, 'sample.zsh', 2, 'helper() { : }\n');
      const refreshed = refreshZshHydrator({
        previous: live,
        projectRoot: root,
        documents: [edited],
      });
      const next = refreshed.files.get('sample.zsh');

      if (!next) {
        throw new Error('entry required');
      }

      expect(next.ast).not.toBe(entry.ast);
      expect(documentationOf(next.functions[0].definition)).toBeNull();
      expect(next.ast.comments).toEqual([]);
      expect(entry.ast.comments.map(directivesOf).flat()).toHaveLength(1);
      const closed = refreshZshHydrator({ previous: refreshed, projectRoot: root, documents: [] });

      expect(
        documentationOf(
          closed.files.get('sample.zsh')?.functions[0].definition ?? entry.functions[0].definition,
        )?.parameters,
      ).toMatchObject([{ kind: 'positionalParameterDoc', description: 'disk' }]);
    });

    test('新規bufferとdot名を扱い、project外の文書を除外する', () => {
      const root = createHydrationFixture();
      const state = createZshHydrator(root);
      const result = refreshZshHydrator({
        previous: state,
        projectRoot: root,
        documents: [
          document(root, '..helper.zsh', 1, 'helper() { : }\n'),
          document(root, 'new.zsh', 1, 'new_function() { : }\n'),
          document(path.dirname(root), 'outside.zsh', 1, 'outside() { : }\n'),
        ],
      });

      expect([...result.files.keys()].toSorted()).toEqual(['..helper.zsh', 'new.zsh']);
    });

    test('解釈設定の変更でdiskとbufferの付加情報を再生成する', () => {
      const root = createHydrationFixture();
      const content = 'helper() { : } # custom: ignore\n';
      fs.writeFileSync(path.join(root, 'disk.zsh'), content);
      const opened = document(root, 'buffer.zsh', 1, content);
      const first = refreshZshHydrator({
        previous: createZshHydrator(root),
        projectRoot: root,
        documents: [opened],
      });
      const next = refreshZshHydrator({
        previous: first,
        projectRoot: root,
        documents: [opened],
        options: { directiveNamespaces: ['custom'] },
      });

      for (const name of ['disk.zsh', 'buffer.zsh']) {
        const entry = next.files.get(name);

        if (!entry) {
          throw new Error('entry required');
        }

        expect(entry).not.toBe(first.files.get(name));
        expect(entry.ast.comments.map(directivesOf).flat()).toHaveLength(1);
      }
    });
  });
});
