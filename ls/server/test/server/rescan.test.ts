import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { describe, expect, test } from 'vitest';
import {
  DidChangeConfigurationNotification,
  DidCloseTextDocumentNotification,
  WorkspaceDiagnosticRequest,
} from 'vscode-languageserver/node';
import { createPeriodicLspClient, createProjectDirectory, withRequestTimeout } from './client';

describe('実サーバー: rescan', () => {
  test('定期走査で通知されなかったdiskの追加・変更・削除・renameと診断を同期する', async () => {
    const root = createProjectDirectory();
    const first = path.join(root, 'first.zsh');
    const added = path.join(root, 'added.zsh');
    const renamed = path.join(root, 'renamed.zsh');
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(first, 'z.original() { : }\n');
    const { client, ticks } = createPeriodicLspClient(root);
    try {
      await client.initialize({ projectRoot: root, supportsRefresh: true });
      await client.open(caller, 'z.');
      await client.items(caller);
      await expect.poll(ticks, { timeout: 1500 }).toBeGreaterThan(0);
      fs.writeFileSync(first, 'z.changed() { : }\n');
      fs.writeFileSync(added, 'z.added() { : }\nfixture_periodic_unknown\n');
      const before = ticks();
      await expect.poll(ticks).toBeGreaterThan(before);
      expect((await client.items(caller)).map((item) => item.label)).toEqual([
        'z.added',
        'z.changed',
      ]);
      fs.renameSync(added, renamed);
      fs.unlinkSync(first);
      const moved = ticks();
      await expect.poll(ticks).toBeGreaterThan(moved);
      expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.added']);
      const workspace = await withRequestTimeout(
        client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }),
      );
      expect(
        workspace.items.find((item) => item.uri === pathToFileURL(renamed).href),
      ).toMatchObject({ version: null, items: [{ code: 'undefined-command' }] });
      expect(workspace.items.some((item) => item.uri === pathToFileURL(first).href)).toBe(false);
    } finally {
      await client.close();
    }
  }, 15000);

  test('定期走査中も未保存bufferを優先し、closeで更新後のdiskへ戻す', async () => {
    const root = createProjectDirectory();
    const filename = path.join(root, 'definition.zsh');
    const uri = pathToFileURL(filename).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(filename, 'z.disk() { : }\n');
    const { client, ticks } = createPeriodicLspClient(root);
    try {
      await client.initialize({ projectRoot: root, supportsRefresh: true });
      await client.open(uri, '# Unsaved docs\nz.live() { : }\n');
      await client.open(caller, 'z.');
      await client.items(caller);
      fs.writeFileSync(filename, 'z.saved() { : }\n');
      const before = ticks();
      await expect.poll(ticks).toBeGreaterThan(before);
      expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.live']);
      await client.connection.sendNotification(DidCloseTextDocumentNotification.type, {
        textDocument: { uri },
      });
      expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.saved']);
    } finally {
      await client.close();
    }
  }, 15000);

  test('定期走査は設定変更後のrootを参照し、project未選択なら走査を休止する', async () => {
    const first = createProjectDirectory();
    const second = createProjectDirectory();
    fs.writeFileSync(path.join(first, 'first.zsh'), 'z.first() { : }\n');
    fs.writeFileSync(path.join(second, 'second.zsh'), 'z.second() { : }\n');
    const caller = pathToFileURL(path.join(first, 'caller.zsh')).href;
    const { client, ticks } = createPeriodicLspClient(first);
    try {
      await client.initialize({ projectRoot: first, supportsRefresh: false, useWorkspace: false });
      await client.open(caller, 'z.');
      await client.items(caller);
      await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
        settings: { 'z-ls': { zPath: second } },
      });
      await client.items(caller);
      fs.writeFileSync(path.join(second, 'new.zsh'), 'z.new() { : }\n');
      const before = ticks();
      await expect.poll(ticks).toBeGreaterThan(before);
      expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.new', 'z.second']);
      await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
        settings: { 'z-ls': { zPath: '' } },
      });
      await client.items(caller);
      const empty = ticks();
      await expect.poll(ticks).toBeGreaterThan(empty);
      expect(await client.items(caller)).toEqual([]);
    } finally {
      await client.close();
    }
  }, 15000);
});
