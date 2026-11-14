import { afterEach, describe, expect, test, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';

const roots: string[] = [];
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});

describe('refreshFunctionSnapshot incremental inputs', () => {
  test('buffer編集ではディスク走査も無関係なstatも実行しない', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-incremental-'));
    roots.push(root);
    fs.writeFileSync(path.join(root, 'a.zsh'), 'first() { : }\n');
    fs.writeFileSync(path.join(root, 'b.zsh'), 'second() { : }\n');
    const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [] });
    const stat = vi.spyOn(fs, 'statSync');
    const read = vi.spyOn(fs, 'readdirSync');
    const changed = refreshFunctionSnapshot({ projectRoot: root, previous, changedPaths: [],
      documents: [TextDocument.create(pathToFileURL(path.join(root, 'a.zsh')).href, 'shellscript', 1, 'edited() { : }\n')] });
    expect(stat).not.toHaveBeenCalled();
    expect(read).not.toHaveBeenCalled();
    expect(changed.hydrator.files.get('b.zsh')).toBe(previous.hydrator.files.get('b.zsh'));
    expect(changed.functions.map(fn => fn.name)).toEqual(['edited', 'second']);
  });
  test('buffer-only関数の保存で同名候補の順序が変わったら投影も更新する', () => {
    const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-incremental-order-'));
    roots.push(root);
    fs.writeFileSync(path.join(root, 'z.zsh'), '# $1: disk\nhelper() { : }\n');
    const opened = TextDocument.create(pathToFileURL(path.join(root, 'a.zsh')).href, 'shellscript', 1,
      '# $2: live\nhelper() { : }\n');
    const previous = refreshFunctionSnapshot({ projectRoot: root, documents: [opened] });
    expect(previous.targets.get('helper')?.map(target => target.info.file)).toEqual(['z.zsh', 'a.zsh']);
    fs.writeFileSync(path.join(root, 'a.zsh'), opened.getText());
    const next = refreshFunctionSnapshot({ projectRoot: root, documents: [opened], previous, changedPaths: ['a.zsh'] });
    expect(next.targets.get('helper')?.map(target => target.info.file)).toEqual(['a.zsh', 'z.zsh']);
    expect(next.hydrator.files.get('a.zsh')).toBe(previous.hydrator.files.get('a.zsh'));
    const fresh = refreshFunctionSnapshot({ projectRoot: root, documents: [opened] });
    expect(next.functions).toEqual(fresh.functions);
  });

});
