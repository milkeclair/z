import { afterEach, describe, expect, test, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { createZshHydrator, refreshZshHydrator, EmptyZshHydrator } from '../../src/zshHydrator';
import type { ZshHydrator } from '../../src/zshHydrator';

const roots: string[] = [];
function fixture() {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-hydrator-diff-'));
  roots.push(root);
  return root;
}
function write(root: string, file: string, content: string) {
  const filename = path.join(root, file);
  fs.mkdirSync(path.dirname(filename), { recursive: true });
  fs.writeFileSync(filename, content);
}
function document(root: string, file: string, version: number, content: string) {
  return TextDocument.create(pathToFileURL(path.join(root, file)).href, 'shellscript', version, content);
}
function parity(state: ZshHydrator, documents: readonly TextDocument[] = []) {
  const fresh = refreshZshHydrator({ previous: EmptyZshHydrator, projectRoot: state.projectRoot,
    documents, options: state.options });
  expect([...state.files.keys()]).toEqual([...fresh.files.keys()]);
  expect([...state.diskPaths].sort()).toEqual([...fresh.diskPaths].sort());
  for (const [filename, entry] of state.files) expect(entry).toEqual(fresh.files.get(filename));
}
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});

describe('zshHydrator incremental updates', () => {
  test('buffer編集だけならdiskを走査せず、他ファイルのASTを共有する', () => {
    const root = fixture();
    write(root, 'a.zsh', 'first() { : }\n');
    write(root, 'b.zsh', 'second() { : }\n');
    const previous = createZshHydrator(root);
    const opened = document(root, 'a.zsh', 1, 'edited() { : }\n');
    const stat = vi.spyOn(fs, 'statSync');
    const directories = vi.spyOn(fs, 'readdirSync');
    const next = refreshZshHydrator({ previous, projectRoot: root, documents: [opened], changedPaths: [] });
    expect(stat).not.toHaveBeenCalled();
    expect(directories).not.toHaveBeenCalled();
    expect(next.files.get('a.zsh')?.functions[0].name).toBe('edited');
    expect(next.files.get('b.zsh')).toBe(previous.files.get('b.zsh'));
    expect(refreshZshHydrator({ previous: next, projectRoot: root, documents: [opened], changedPaths: [] })).toBe(next);
    parity(next, [opened]);
  });

  test('通知されたdiskだけstat/readし、ASTと変更前の状態を保持する', () => {
    const root = fixture();
    write(root, 'a.zsh', 'first() { : }\n');
    write(root, 'b.zsh', 'second() { : }\n');
    const previous = createZshHydrator(root);
    write(root, 'a.zsh', 'changed() { : }\n');
    const stat = vi.spyOn(fs, 'statSync');
    const read = vi.spyOn(fs, 'readFileSync');
    const directories = vi.spyOn(fs, 'readdirSync');
    const next = refreshZshHydrator({ previous, projectRoot: root, documents: [],
      changedPaths: ['a.zsh', path.join(root, 'a.zsh')] });
    expect(stat.mock.calls.map(args => args[0])).toEqual([path.join(root, 'a.zsh')]);
    expect(read.mock.calls.map(args => args[0])).toEqual([path.join(root, 'a.zsh')]);
    expect(directories).not.toHaveBeenCalled();
    expect(next.files.get('b.zsh')).toBe(previous.files.get('b.zsh'));
    expect(previous.files.get('a.zsh')?.functions[0].name).toBe('first');
    expect(next.files.get('a.zsh')?.functions[0].name).toBe('changed');
    parity(next);
  });

  test('作成・削除・renameを最終disk状態から反映し、順不同通知でも全走査と一致する', () => {
    const root = fixture();
    write(root, 'z.zsh', 'last() { : }\n');
    write(root, 'old.zsh', 'old() { : }\n');
    const previous = createZshHydrator(root);
    fs.renameSync(path.join(root, 'old.zsh'), path.join(root, 'a.zsh'));
    write(root, 'b.zsh', 'added() { : }\n');
    const next = refreshZshHydrator({ previous, projectRoot: root, documents: [],
      changedPaths: ['b.zsh', 'old.zsh', 'a.zsh', 'b.zsh'] });
    expect([...next.files.keys()]).toEqual(['a.zsh', 'b.zsh', 'z.zsh']);
    parity(next);
    expect(refreshZshHydrator({ previous: next, projectRoot: root, documents: [],
      changedPaths: ['old.zsh', 'b.zsh'] })).toBe(next);
  });

  test.each(['change', 'delete', 'replace-directory'])('open中のdisk %sよりbufferを優先し、closeでdiskへ戻す', change => {
    const root = fixture();
    write(root, 'file.zsh', 'disk() { : }\n');
    const opened = document(root, 'file.zsh', 1, 'live() { : }\n');
    const previous = refreshZshHydrator({ previous: createZshHydrator(root), projectRoot: root, documents: [opened], changedPaths: [] });
    if (change === 'change') write(root, 'file.zsh', 'saved() { : }\n');
    else {
      fs.unlinkSync(path.join(root, 'file.zsh'));
      if (change === 'replace-directory') fs.mkdirSync(path.join(root, 'file.zsh'));
    }
    const next = refreshZshHydrator({ previous, projectRoot: root, documents: [opened], changedPaths: ['file.zsh'] });
    expect(next.files.get('file.zsh')).toBe(previous.files.get('file.zsh'));
    parity(next, [opened]);
    const closed = refreshZshHydrator({ previous: next, projectRoot: root, documents: [], changedPaths: [] });
    expect(closed.files.get('file.zsh')?.functions[0].name).toBe(change === 'change' ? 'saved' : undefined);
    parity(closed);
  });

  test('buffer-only文書の保存でdisk順序へ移し、未通知のdisk文書もopen時に対象だけ確認する', () => {
    const root = fixture();
    write(root, 'z.zsh', 'same() { : }\n');
    const initial = createZshHydrator(root);
    const opened = document(root, 'a.zsh', 1, 'same() { : }\n');
    const live = refreshZshHydrator({ previous: initial, projectRoot: root, documents: [opened], changedPaths: [] });
    expect([...live.files.keys()]).toEqual(['z.zsh', 'a.zsh']);
    write(root, 'a.zsh', opened.getText());
    const saved = refreshZshHydrator({ previous: live, projectRoot: root, documents: [opened], changedPaths: ['a.zsh'] });
    expect([...saved.files.keys()]).toEqual(['a.zsh', 'z.zsh']);
    expect(saved.files.get('a.zsh')).toBe(live.files.get('a.zsh'));
    parity(saved, [opened]);
    write(root, 'new.zsh', 'new_disk() { : }\n');
    const additional = document(root, 'new.zsh', 1, 'new_live() { : }\n');
    const next = refreshZshHydrator({ previous: saved, projectRoot: root, documents: [opened, additional], changedPaths: [] });
    parity(next, [opened, additional]);
  });

  test('hiddenパスを含め、git・依存・project外・対象外拡張子のdisk通知を除外する', () => {
    const root = fixture();
    const previous = createZshHydrator(root);
    for (const file of ['.hidden.zsh', '.config/helper.zsh', '.git/ignored.zsh', 'node_modules/ignored.zsh', 'ignored.txt']) write(root, file, 'helper() { : }\n');
    const outside = path.join(path.dirname(root), path.basename(root) + '-outside.zsh');
    const stat = vi.spyOn(fs, 'statSync');
    const next = refreshZshHydrator({ previous, projectRoot: root, documents: [], changedPaths: [
      '.hidden.zsh', '.config/helper.zsh', '.git/ignored.zsh', 'node_modules/ignored.zsh', 'ignored.txt', outside,
    ] });
    expect(stat.mock.calls.map(args => args[0])).toEqual([path.join(root, '.hidden.zsh'), path.join(root, '.config/helper.zsh')]);
    expect([...next.files.keys()]).toEqual(['.config/helper.zsh', '.hidden.zsh']);
    parity(next);
  });

  test('rootまたは解釈設定が変われば空の差分指定でも全体を作り直す', () => {
    const first = fixture();
    const second = fixture();
    write(first, 'first.zsh', 'first() { : }\n');
    write(second, 'second.zsh', 'second() { : } # custom: ignore\n');
    const previous = createZshHydrator(first);
    const moved = refreshZshHydrator({ previous, projectRoot: second, documents: [], changedPaths: [] });
    expect([...moved.files.keys()]).toEqual(['second.zsh']);
    const configured = refreshZshHydrator({ previous: moved, projectRoot: second, documents: [], changedPaths: [],
      options: { directiveNamespaces: ['custom'] } });
    expect(configured.files.get('second.zsh')).not.toBe(moved.files.get('second.zsh'));
    parity(configured);
  });

  test('通知されたパスの権限エラーを返し、以前の状態はそのまま保持する', () => {
    const root = fixture();
    write(root, 'file.zsh', 'helper() { : }\n');
    const previous = createZshHydrator(root);
    const denied = Object.assign(new Error('denied'), { code: 'EACCES' });
    const original = fs.statSync;
    vi.spyOn(fs, 'statSync').mockImplementation((...args) => {
      if (args[0] === path.join(root, 'file.zsh')) throw denied;
      return original(...args);
    });
    expect(() => refreshZshHydrator({ previous, projectRoot: root, documents: [], changedPaths: ['file.zsh'] })).toThrow(denied);
    expect(previous.files.get('file.zsh')?.functions[0].name).toBe('helper');
  });
});
