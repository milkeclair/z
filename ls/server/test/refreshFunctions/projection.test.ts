import * as Immutable from 'immutable';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

function createSnapshotFixture(files: Readonly<Record<string, string>>): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-file-projection-'));
  temporaryDirectories.track(root);

  for (const [file, content] of Object.entries(files)) {
    fs.writeFileSync(path.join(root, file), content);
  }

  return root;
}

function document(root: string, file: string, version: number, content: string) {
  return TextDocument.create(
    pathToFileURL(path.join(root, file)).href,
    'shellscript',
    version,
    content,
  );
}

afterEach(() => {
  temporaryDirectories.cleanup();
});

describe('projectFunctions', () => {
  describe('ファイルごとの関数情報を投影する場合', () => {
    test('変更した関数の説明・引数・位置だけを更新し、未変更の関数情報を共有する', () => {
      const root = createSnapshotFixture({
        'a.zsh': '# Old description\n# $1: old argument\nhelper() { : }\n',
        'b.zsh': '# Stable description\n# $1: stable argument\nstable() { : }\n',
      });
      const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
      const opened = document(
        root,
        'a.zsh',
        1,
        '\n# New description\n# $2?: next argument\nhelper() { : }\n',
      );
      const next = refreshFunctionSnapshot({
        projectRoot: root,
        previous,
        documents: [opened],
        changedPaths: [],
      });

      expect(next.functions[0]).toMatchObject({
        line: 4,
        args: [{ position: 2, name: 'next argument', optional: true }],
        documentation: { description: 'New description' },
      });
      expect(next.targets.get('helper')?.[0].nameNode.range.start.line).toBe(3);
      expect(next.targets.get('helper')?.[0].definition).not.toBe(
        previous.targets.get('helper')?.[0].definition,
      );
      expect(next.functions[1]).toBe(previous.functions[1]);
      expect(next.functions[1].args).toBe(previous.functions[1].args);
      expect(next.functions[1].documentation).toBe(previous.functions[1].documentation);
      expect(next.targets.get('stable')?.[0]).toBe(previous.targets.get('stable')?.[0]);
      expect(previous.functions[0]).toMatchObject({
        line: 3,
        documentation: { description: 'Old description' },
      });
      const fresh = refreshFunctionSnapshot({ projectRoot: root, documents: [opened] });

      expect(next.functions).toEqual(fresh.functions);
      expect(next.targets).toEqual(fresh.targets);
    });

    test('同名候補を持つファイルを編集しても、別ファイルの候補と以前の配列を変更しない', () => {
      const root = createSnapshotFixture({
        'a.zsh': 'helper() { : }\n',
        'b.zsh': '# $1: second\nhelper() { : }\n',
      });
      const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
      const candidates = previous.targets.get('helper');

      expect(candidates?.length).toBe(2);
      const next = refreshFunctionSnapshot({
        projectRoot: root,
        previous,
        changedPaths: [],
        documents: [document(root, 'a.zsh', 1, 'renamed() { : }\n')],
      });

      expect(next.targets.get('helper')).toHaveLength(1);
      expect(next.targets.get('helper')?.[0]).toBe(candidates?.[1]);
      expect(previous.targets.get('helper')).toBe(candidates);
      expect(candidates?.map((target) => target.info.file)).toEqual(['a.zsh', 'b.zsh']);
      expect(next.functions.map((info) => info.name)).toEqual(['renamed', 'helper']);
    });

    test('保存とcloseで最新のdiskへ戻し、無関係なファイルの投影を共有する', () => {
      const root = createSnapshotFixture({
        'a.zsh': '# Disk\nhelper() { : }\n',
        'b.zsh': 'stable() { : }\n',
      });
      const opened = document(root, 'a.zsh', 1, '# Buffer\nhelper() { : }\n');
      const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [opened] });
      fs.writeFileSync(path.join(root, 'a.zsh'), '# Saved\nhelper() { : }\n');
      const savedDocument = document(root, 'a.zsh', 2, '# Saved\nhelper() { : }\n');
      const saved = refreshFunctionSnapshot({
        projectRoot: root,
        previous,
        documents: [savedDocument],
        changedPaths: ['a.zsh'],
      });
      fs.writeFileSync(path.join(root, 'a.zsh'), '\n# Latest disk\nhelper() { : }\n');
      const closed = refreshFunctionSnapshot({
        projectRoot: root,
        previous: saved,
        documents: [],
        changedPaths: [],
      });

      expect(saved.functions[0].documentation?.description).toBe('Saved');
      expect(closed.functions[0]).toMatchObject({
        line: 3,
        documentation: { description: 'Latest disk' },
      });
      expect(closed.functions[1]).toBe(previous.functions[1]);
      expect(saved.targets.get('stable')?.[0]).toBe(previous.targets.get('stable')?.[0]);
      expect(closed.targets.get('stable')?.[0]).toBe(previous.targets.get('stable')?.[0]);
      expect(previous.functions[0].documentation?.description).toBe('Buffer');
      const fresh = refreshFunctionSnapshot({ projectRoot: root, documents: [] });

      expect(closed.functions).toEqual(fresh.functions);
      expect(closed.targets).toEqual(fresh.targets);
    });

    test('複数名を持つ定義を一度だけ変換し、他ファイルの編集で共有する', () => {
      const root = createSnapshotFixture({
        'a.zsh': '# $1: shared argument\nfunction -T first second () { : }\n',
        'b.zsh': 'other() { : }\n',
      });
      const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [] });

      expect(previous.functions.map((info) => info.name)).toEqual(['first', 'second', 'other']);
      expect(previous.functions[0].args).toBe(previous.functions[1].args);
      expect(previous.functions[0].args).toHaveLength(1);
      expect(previous.targets.get('first')?.[0].definition).toBe(
        previous.targets.get('second')?.[0].definition,
      );
      const next = refreshFunctionSnapshot({
        projectRoot: root,
        previous,
        changedPaths: [],
        documents: [document(root, 'b.zsh', 1, 'edited() { : }\n')],
      });

      expect(next.functions[0]).toBe(previous.functions[0]);
      expect(next.functions[1]).toBe(previous.functions[1]);
      expect(next.targets.get('second')?.[0]).toBe(previous.targets.get('second')?.[0]);
      expect(next.functions.map((info) => info.name)).toEqual(['first', 'second', 'edited']);
    });

    test('rename・削除・関数の消失で不要な投影を外し、候補を全走査と一致させる', () => {
      const root = createSnapshotFixture({
        'a.zsh': 'first() { : }\n',
        'b.zsh': 'second() { : }\n',
      });
      const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
      const oldFile = previous.hydrator.files.get('a.zsh');

      expect(oldFile).toBeDefined();
      fs.renameSync(path.join(root, 'a.zsh'), path.join(root, 'c.zsh'));
      const renamed = refreshFunctionSnapshot({
        projectRoot: root,
        previous,
        documents: [],
        changedPaths: ['a.zsh', 'c.zsh'],
      });

      expect([...renamed.fileProjections.keys()]).not.toContain(oldFile);
      expect(renamed.fileProjections.size).toBe(2);
      expect(renamed.functions.map((info) => info.file)).toEqual(['b.zsh', 'c.zsh']);
      expect(renamed.targets.get('second')?.[0]).toBe(previous.targets.get('second')?.[0]);
      expect(renamed.targets.get('first')?.[0].uri).toBe(
        pathToFileURL(path.join(root, 'c.zsh')).href,
      );
      const fresh = refreshFunctionSnapshot({ projectRoot: root, documents: [] });

      expect(renamed.functions).toEqual(fresh.functions);
      expect(renamed.targets).toEqual(fresh.targets);
      fs.unlinkSync(path.join(root, 'c.zsh'));
      fs.writeFileSync(path.join(root, 'b.zsh'), 'print done\n');
      const removed = refreshFunctionSnapshot({
        projectRoot: root,
        previous: renamed,
        documents: [],
        changedPaths: ['b.zsh', 'c.zsh'],
      });

      expect(removed.fileProjections.size).toBe(0);
      expect(removed.functions).toEqual([]);
      expect(removed.targets.size).toBe(0);
      expect(previous.fileProjections.size).toBe(2);
    });

    test('連続編集でも現在のhydrationだけをキャッシュに保持する', () => {
      const root = createSnapshotFixture({ 'a.zsh': 'helper() { : }\n' });
      const initial = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
      Immutable.Range(1, 21).reduce((previous, version) => {
        const next = refreshFunctionSnapshot({
          projectRoot: root,
          previous,
          changedPaths: [],
          documents: [document(root, 'a.zsh', version, '# edit ' + version + '\nhelper() { : }\n')],
        });

        expect(next.fileProjections.size).toBe(1);
        expect([...next.fileProjections.keys()]).toEqual([...next.hydrator.files.values()]);
        expect([...next.fileProjections.keys()]).not.toContain(
          [...previous.fileProjections.keys()][0],
        );
        expect(previous.fileProjections.size).toBe(1);

        return next;
      }, initial);
    });

    test('同じ相対パスのroot切替とproject解除で古い投影を解放する', () => {
      const root = createSnapshotFixture({ 'a.zsh': '# First root\nhelper() { : }\n' });
      const other = createSnapshotFixture({ 'a.zsh': '# Second root\nhelper() { : }\n' });
      const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
      const next = refreshFunctionSnapshot({
        projectRoot: other,
        previous,
        documents: [],
        changedPaths: [],
      });

      expect(next.functions[0].documentation?.description).toBe('Second root');
      expect(next.targets.get('helper')?.[0].uri).toBe(
        pathToFileURL(path.join(other, 'a.zsh')).href,
      );
      expect([...next.fileProjections.keys()]).not.toContain(
        [...previous.fileProjections.keys()][0],
      );
      const cleared = refreshFunctionSnapshot({ projectRoot: '', previous: next, documents: [] });

      expect(cleared.fileProjections.size).toBe(0);
      expect(cleared.targets.size).toBe(0);
      expect(cleared.functions).toEqual([]);
      expect(previous.functions[0].documentation?.description).toBe('First root');
    });
  });
});
