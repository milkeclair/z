import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { describe, expect, test } from 'vitest';
import {
  CompletionResolveRequest,
  DefinitionRequest,
  DidChangeConfigurationNotification,
  DidChangeWatchedFilesNotification,
  DidCloseTextDocumentNotification,
  DidSaveTextDocumentNotification,
  DocumentDiagnosticRequest,
  FileChangeType,
  HoverRequest,
  SignatureHelpRequest,
} from 'vscode-languageserver/node';
import { createLspClient, createProjectDirectory, withRequestTimeout } from './client';

describe('startServer', () => {
  describe('プロジェクトと文書を同期する場合', () => {
    test('workspaceのない接続は設定変更で解析対象を切り替える', async () => {
      const first = createProjectDirectory();
      const second = createProjectDirectory();
      fs.writeFileSync(path.join(first, 'functions.zsh'), 'z.first() { : }\n');
      fs.writeFileSync(path.join(second, 'functions.zsh'), 'z.second() { : }\n');
      const uri = pathToFileURL(path.join(first, 'caller.zsh')).href;
      const client = createLspClient();

      try {
        await client.initialize({
          projectRoot: first,
          supportsRefresh: false,
          useWorkspace: false,
        });
        await client.open(uri, 'z.');

        expect((await client.items(uri)).map((item) => item.label)).toEqual(['z.first']);
        await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
          settings: { 'z-ls': { zPath: second } },
        });

        expect((await client.items(uri)).map((item) => item.label)).toEqual(['z.second']);
        await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
          settings: { 'z-ls': { zPath: '' } },
        });

        expect(await client.items(uri)).toEqual([]);
      } finally {
        await client.close();
      }
    }, 15000);

    test('文書イベントを処理し、編集直後の関数・文書情報とdiskの復元を返す', async () => {
      const root = createProjectDirectory();
      const definition = path.join(root, 'functions.zsh');
      const definitionUri = pathToFileURL(definition).href;
      const callerUri = pathToFileURL(path.join(root, 'caller.zsh')).href;
      fs.writeFileSync(definition, '# Disk docs\n# $1: disk\nz.disk() { print "$1" }\n');
      const client = createLspClient();

      try {
        const initialized = await client.initialize({ projectRoot: root, supportsRefresh: true });

        expect(initialized.capabilities.textDocumentSync).toMatchObject({ save: true });
        await client.open(callerUri, 'z.');

        expect((await client.items(callerUri)).map((item) => item.label)).toContain('z.disk');

        await client.open(definitionUri, '# Live docs\n# $1: unsaved\nz.live() { print "$1" }\n');
        const items = await client.items(callerUri);

        expect(items.map((item) => item.label)).toContain('z.live');
        expect(items.map((item) => item.label)).not.toContain('z.disk');
        const live = items.find((item) => item.label === 'z.live');

        if (!live) {
          throw new Error('live completion required');
        }

        expect(live.data).toMatchObject({ line: 3, args: [{ name: 'unsaved', position: 1 }] });
        const resolved = await withRequestTimeout(
          client.connection.sendRequest(CompletionResolveRequest.type, live),
        );

        expect(resolved.documentation).toMatchObject({
          value: expect.stringContaining('Live docs'),
        });

        await client.edit(callerUri, 'z.live', 2);
        await client.edit(
          definitionUri,
          '# Edited docs\n# $1: edited\nz.live() { print "$1" }\n',
          2,
        );
        const hovered = await withRequestTimeout(
          client.connection.sendRequest(HoverRequest.type, {
            textDocument: { uri: callerUri },
            position: { line: 0, character: 4 },
          }),
        );

        expect(hovered).toMatchObject({
          contents: { value: expect.stringContaining('Edited docs') },
        });

        await client.edit(callerUri, 'z.live ', 3);
        const signature = await withRequestTimeout(
          client.connection.sendRequest(SignatureHelpRequest.type, {
            textDocument: { uri: callerUri },
            position: { line: 0, character: 7 },
          }),
        );

        expect(signature).toMatchObject({
          signatures: [{ parameters: [{ documentation: { value: 'edited' } }] }],
        });

        const extra = path.join(root, 'extra.zsh');
        fs.writeFileSync(extra, 'z.extra() { : }\n');
        fs.writeFileSync(definition, 'z.saved() { : }\n');
        await client.connection.sendNotification(DidSaveTextDocumentNotification.type, {
          textDocument: { uri: definitionUri },
        });
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [{ uri: pathToFileURL(extra).href, type: FileChangeType.Created }],
        });
        await client.edit(callerUri, 'z.', 4);

        expect((await client.items(callerUri)).map((item) => item.label)).toEqual([
          'z.extra',
          'z.live',
        ]);

        await client.connection.sendNotification(DidCloseTextDocumentNotification.type, {
          textDocument: { uri: definitionUri },
        });

        expect((await client.items(callerUri)).map((item) => item.label)).toEqual([
          'z.extra',
          'z.saved',
        ]);
        const stale = await withRequestTimeout(
          client.connection.sendRequest(CompletionResolveRequest.type, live),
        );

        expect(stale.documentation).toBeUndefined();

        fs.unlinkSync(extra);
        const watched = path.join(root, 'watched.zsh');
        fs.writeFileSync(watched, 'z.watched() { : }\n');
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [
            { uri: pathToFileURL(extra).href, type: FileChangeType.Deleted },
            { uri: pathToFileURL(watched).href, type: FileChangeType.Created },
          ],
        });

        expect((await client.items(callerUri)).map((item) => item.label)).toEqual([
          'z.saved',
          'z.watched',
        ]);
        const diagnostic = await withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: callerUri },
          }),
        );

        expect(diagnostic).toMatchObject({ kind: 'full', items: expect.any(Array) });
        await expect.poll(() => client.refreshRequests.length).toBeGreaterThan(0);
        expect(client.registrations).toEqual(['workspace/didChangeWatchedFiles']);
      } finally {
        await client.close();
      }
    }, 15000);

    test('一般名の新規buffer・workspace境界と任意capabilityのないクライアントを扱う', async () => {
      const root = createProjectDirectory();
      const uri = pathToFileURL(path.join(root, 'new.zsh')).href;
      const outside = pathToFileURL(path.join(path.dirname(root), 'outside.zsh')).href;
      const client = createLspClient();

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        await client.open(uri, '# New docs\ngreet() { : }\n');
        await client.open(outside, 'z.outside() { : }\n');
        await client.edit(uri, 'gre\n# New docs\ngreet() { : }\n', 2);
        const items = await client.items(uri, 3);

        expect(items.map((item) => item.label)).toEqual(['greet']);
        expect(items[0].textEdit).toMatchObject({
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: 3 },
          },
          newText: 'greet',
        });
        const hovered = await withRequestTimeout(
          client.connection.sendRequest(HoverRequest.type, {
            textDocument: { uri },
            position: { line: 0, character: 2 },
          }),
        );
        const resolved = await withRequestTimeout(
          client.connection.sendRequest(CompletionResolveRequest.type, items[0]),
        );

        expect(resolved.documentation).toMatchObject({
          value: expect.stringContaining('New docs'),
        });
        expect(hovered).toBeNull();
        await client.edit(uri, 'greet\n# New docs\ngreet() { : }\n', 3);
        const fullHover = await withRequestTimeout(
          client.connection.sendRequest(HoverRequest.type, {
            textDocument: { uri },
            position: { line: 0, character: 2 },
          }),
        );

        expect(fullHover).toMatchObject({
          contents: { value: expect.stringContaining('New docs') },
        });
        await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
          settings: {
            'z-ls': {
              zPath: path.join(root, 'ignored'),
              completion: { showPrivateFunctions: true },
            },
          },
        });

        expect((await client.items(uri, 3)).map((item) => item.label)).toEqual(['greet']);
        await new Promise((resolve) => setTimeout(resolve, 650));

        expect(client.registrations).toEqual([]);
        expect(client.refreshRequests).toEqual([]);
      } finally {
        await client.close();
      }
    }, 15000);

    test('一般名の呼び出し・複数行引数・正確な定義位置を実サーバーで返す', async () => {
      const root = createProjectDirectory();
      const definition = path.join(root, '日本語 name.zsh');
      const definitionUri = pathToFileURL(definition).href;
      fs.writeFileSync(
        definition,
        '# Greeting\n# $1: first\n# $2: second\n  function greet { : }\n',
      );
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      const client = createLspClient();

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        await client.open(caller, 'greet "hello\nworld" ');
        const signature = await withRequestTimeout(
          client.connection.sendRequest(SignatureHelpRequest.type, {
            textDocument: { uri: caller },
            position: { line: 1, character: 7 },
          }),
        );

        expect(signature).toMatchObject({
          activeParameter: 1,
          signatures: [
            {
              parameters: [
                { documentation: { value: 'first' } },
                { documentation: { value: 'second' } },
              ],
            },
          ],
        });
        const location = await withRequestTimeout(
          client.connection.sendRequest(DefinitionRequest.type, {
            textDocument: { uri: caller },
            position: { line: 0, character: 2 },
          }),
        );

        expect(location).toEqual({
          uri: definitionUri,
          range: {
            start: { line: 3, character: 11 },
            end: { line: 3, character: 16 },
          },
        });

        for (const [version, text] of [
          'print "greet"',
          '# greet',
          'print > greet',
          'builtin greet',
        ].entries()) {
          await client.edit(caller, text, version + 2);
          const character = text.indexOf('greet') + 2;

          expect(
            await withRequestTimeout(
              client.connection.sendRequest(DefinitionRequest.type, {
                textDocument: { uri: caller },
                position: { line: 0, character },
              }),
            ),
          ).toBeNull();
          expect(
            await withRequestTimeout(
              client.connection.sendRequest(HoverRequest.type, {
                textDocument: { uri: caller },
                position: { line: 0, character },
              }),
            ),
          ).toBeNull();
        }

        await client.edit(caller, 'print "$(greet x )"', 7);

        expect(
          await withRequestTimeout(
            client.connection.sendRequest(SignatureHelpRequest.type, {
              textDocument: { uri: caller },
              position: { line: 0, character: 17 },
            }),
          ),
        ).toMatchObject({ activeParameter: 1 });
      } finally {
        await client.close();
      }
    }, 15000);

    test('watcher未対応なら文書編集時に全走査する', async () => {
      const root = createProjectDirectory();
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      const client = createLspClient({ rejectWatchRegistration: false });

      try {
        await client.initialize({
          projectRoot: root,
          supportsRefresh: false,
          useWorkspace: true,
        });
        await client.open(caller, 'gre');
        await client.items(caller, 3);
        fs.writeFileSync(path.join(root, 'added.zsh'), 'greet() { : }\n');
        await client.edit(caller, 'gree', 2);

        expect((await client.items(caller, 4)).map((item) => item.label)).toEqual(['greet']);
        fs.unlinkSync(path.join(root, 'added.zsh'));
        await client.edit(caller, 'gre', 3);

        expect(await client.items(caller, 3)).toEqual([]);
        expect(client.registrations).toEqual([]);
      } finally {
        await client.close();
      }
    }, 15000);

    test('watcher登録を拒否されたら文書編集時に全走査する', async () => {
      const root = createProjectDirectory();
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      const client = createLspClient({ rejectWatchRegistration: true });

      try {
        await client.initialize({
          projectRoot: root,
          supportsRefresh: true,
          useWorkspace: true,
        });
        await client.open(caller, 'gre');
        await client.items(caller, 3);
        fs.writeFileSync(path.join(root, 'added.zsh'), 'greet() { : }\n');
        await client.edit(caller, 'gree', 2);

        expect((await client.items(caller, 4)).map((item) => item.label)).toEqual(['greet']);
        fs.unlinkSync(path.join(root, 'added.zsh'));
        await client.edit(caller, 'gre', 3);

        expect(await client.items(caller, 3)).toEqual([]);
        expect(client.registrations).toEqual(['workspace/didChangeWatchedFiles']);
      } finally {
        await client.close();
      }
    }, 15000);

    test('workspaceがなければ文書編集時に全走査する', async () => {
      const root = createProjectDirectory();
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      const client = createLspClient({ rejectWatchRegistration: false });

      try {
        await client.initialize({
          projectRoot: root,
          supportsRefresh: true,
          useWorkspace: false,
        });
        await client.open(caller, 'gre');
        await client.items(caller, 3);
        fs.writeFileSync(path.join(root, 'added.zsh'), 'greet() { : }\n');
        await client.edit(caller, 'gree', 2);

        expect((await client.items(caller, 4)).map((item) => item.label)).toEqual(['greet']);
        fs.unlinkSync(path.join(root, 'added.zsh'));
        await client.edit(caller, 'gre', 3);

        expect(await client.items(caller, 3)).toEqual([]);
        expect(client.registrations).toEqual(['workspace/didChangeWatchedFiles']);
      } finally {
        await client.close();
      }
    }, 15000);

    test('watcher利用時は編集で未知のdiskを走査せず、通知・save・closeで対象だけ反映する', async () => {
      const root = createProjectDirectory();
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      const definition = path.join(root, 'a.zsh');
      const uri = pathToFileURL(definition).href;
      const client = createLspClient();

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: true });
        await client.open(caller, 'z.');
        await client.items(caller);

        // 登録後の更新を確認し、差分更新の経路に入ったことを確かめる。
        await expect.poll(() => client.refreshRequests.length).toBeGreaterThan(0);
        fs.writeFileSync(definition, 'z.disk() { : }\n');
        await client.edit(caller, 'z.d', 2);

        expect(await client.items(caller, 3)).toEqual([]);
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [{ uri, type: FileChangeType.Created }],
        });

        expect((await client.items(caller, 3)).map((item) => item.label)).toEqual(['z.disk']);
        await client.open(uri, 'z.live() { : }\n');
        await client.edit(caller, 'z.', 3);

        expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.live']);
        fs.writeFileSync(definition, 'z.saved() { : }\n');
        await client.connection.sendNotification(DidSaveTextDocumentNotification.type, {
          textDocument: { uri },
        });

        expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.live']);
        fs.unlinkSync(definition);
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [
            { uri, type: FileChangeType.Deleted },
            { uri: 'untitled:ignored.zsh', type: FileChangeType.Created },
          ],
        });

        expect((await client.items(caller)).map((item) => item.label)).toEqual(['z.live']);
        await client.connection.sendNotification(DidCloseTextDocumentNotification.type, {
          textDocument: { uri },
        });

        expect(await client.items(caller)).toEqual([]);
      } finally {
        await client.close();
      }
    }, 15000);
  });
});
