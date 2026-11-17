import { Range } from 'immutable';
import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { describe, expect, test } from 'vitest';
import {
  CompletionResolveRequest,
  DefinitionRequest,
  DidChangeWatchedFilesNotification,
  DidCloseTextDocumentNotification,
  DidSaveTextDocumentNotification,
  DocumentDiagnosticRequest,
  FileChangeType,
  HoverRequest,
  SignatureHelpRequest,
  WorkspaceDiagnosticRequest,
} from 'vscode-languageserver/node';
import {
  createLspClient,
  createObservedLspClient,
  createProjectDirectory,
  withRequestTimeout,
} from './client';

describe('実サーバー: analysis', () => {
  test('連続編集を最新内容の一回の解析へまとめ、補完要求では待機せず反映する', async () => {
    const root = createProjectDirectory();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(filename, 'greet_old() { : }\n');
    const { client, parsed } = createObservedLspClient(root);
    try {
      await client.initialize({ projectRoot: root, supportsRefresh: true });
      await client.open(uri, 'greet_old() { : }\n');
      await client.open(caller, 'greet_');
      await client.items(caller, 6);
      const before = parsed();
      for (const version of Range(2, 101 + 1)) {
        await client.edit(uri, '# Version ' + version + '\ngreet_final() { : }\n', version);
      }
      expect((await client.items(caller, 6)).map((item) => item.label)).toEqual(['greet_final']);
      const additions = parsed().slice(before.length);
      expect(additions.filter((record) => record.includes('greet_final'))).toHaveLength(1);
      expect(additions).toEqual([expect.stringContaining('Version 101')]);
    } finally {
      await client.close();
    }
  }, 15000);

  test('要求がなくても待機後に最新bufferを解析する', async () => {
    const root = createProjectDirectory();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    fs.writeFileSync(filename, 'old() { : }\n');
    const { client, parsed } = createObservedLspClient(root);
    try {
      await client.initialize({ projectRoot: root, supportsRefresh: false });
      await client.open(uri, 'old() { : }\n');
      await client.items(uri);
      const before = parsed();
      for (const version of Range(2, 101 + 1)) {
        await client.edit(uri, '# Version ' + version + '\nquiet_latest() { : }\n', version);
      }
      await expect
        .poll(
          () =>
            parsed()
              .slice(before.length)
              .filter((record) => record.includes('quiet_latest')).length,
        )
        .toBe(1);
      expect(parsed()).toContainEqual(expect.stringContaining('Version 101'));
    } finally {
      await client.close();
    }
  }, 15000);

  test('各providerは保留中の編集を反映し、save/closeは複数のdisk通知も引き継ぐ', async () => {
    const root = createProjectDirectory();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    const initial = '# First docs\n# $1: first\ngreet() { print "$1" }\n';
    fs.writeFileSync(filename, initial);
    const client = createLspClient();
    try {
      await client.initialize({ projectRoot: root, supportsRefresh: true });
      await client.open(uri, initial);
      await client.open(caller, 'gre');
      const completion = (await client.items(caller, 3)).find((item) => item.label === 'greet');
      if (!completion) {
        throw new Error('greet completion required');
      }
      const later = initial.replace('First', 'Later');
      await client.edit(uri, later, 2);
      expect(
        await withRequestTimeout(
          client.connection.sendRequest(CompletionResolveRequest.type, completion),
        ),
      ).toMatchObject({ documentation: { value: expect.stringContaining('Later docs') } });
      await client.edit(uri, '\n' + later, 3);
      await client.edit(caller, 'greet one\n', 2);
      const params = { textDocument: { uri: caller }, position: { line: 0, character: 2 } };
      expect(
        await withRequestTimeout(client.connection.sendRequest(DefinitionRequest.type, params)),
      ).toMatchObject({ uri, range: { start: { line: 3 } } });
      const fresh = '\n' + later.replace('Later', 'Fresh');
      await client.edit(uri, fresh, 4);
      expect(
        await withRequestTimeout(client.connection.sendRequest(HoverRequest.type, params)),
      ).toMatchObject({ contents: { value: expect.stringContaining('Fresh docs') } });
      await client.edit(uri, fresh.replace('$1: first', '$2: second'), 5);
      expect(
        await withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: caller },
          }),
        ),
      ).toMatchObject({
        items: [
          { code: 'missing-positional-argument', message: 'Missing required argument(s): $2' },
        ],
      });
      const newest = fresh.replace('$1: first', '$1: newest');
      await client.edit(uri, newest, 6);
      await client.edit(caller, 'greet ', 3);
      expect(
        await withRequestTimeout(
          client.connection.sendRequest(SignatureHelpRequest.type, {
            textDocument: { uri: caller },
            position: { line: 0, character: 6 },
          }),
        ),
      ).toMatchObject({ signatures: [{ parameters: [{ documentation: { value: 'newest' } }] }] });
      await client.edit(uri, newest + 'fixture_debounce_never_defined\n', 7);
      const workspace = await withRequestTimeout(
        client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }),
      );
      expect(workspace.items.find((item) => item.uri === uri)).toMatchObject({
        version: 7,
        items: [{ code: 'empty-line' }, { code: 'undefined-command' }],
      });

      const watched = path.join(root, 'watched.zsh');
      fs.writeFileSync(watched, 'watch_merged() { : }\n');
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
        changes: [{ uri: pathToFileURL(watched).href, type: FileChangeType.Created }],
      });
      await client.edit(uri, 'greet_live() { : }\n', 8);
      await client.connection.sendNotification(DidSaveTextDocumentNotification.type, {
        textDocument: { uri },
      });
      await client.edit(caller, 'watch_', 4);
      expect((await client.items(caller, 6)).map((item) => item.label)).toEqual(['watch_merged']);
      await client.edit(uri, 'greet_pending() { : }\n', 9);
      fs.writeFileSync(filename, 'greet_disk() { : }\n');
      await client.connection.sendNotification(DidCloseTextDocumentNotification.type, {
        textDocument: { uri },
      });
      await client.edit(caller, 'greet_', 5);
      expect((await client.items(caller, 6)).map((item) => item.label)).toEqual(['greet_disk']);
    } finally {
      await client.close();
    }
  }, 15000);

  test('shutdown時に保留中の解析を破棄し、タイマーを残さず終了する', async () => {
    const root = createProjectDirectory();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    fs.writeFileSync(filename, 'old() { : }\n');
    const { client, parsed } = createObservedLspClient(root);
    try {
      await client.initialize({ projectRoot: root, supportsRefresh: false });
      await client.open(uri, 'old() { : }\n');
      await client.items(uri);
      const before = parsed();
      await client.edit(uri, 'discarded_on_shutdown() { : }\n', 2);
      await client.close();
      expect(parsed()).toEqual(before);
    } finally {
      await client.close();
    }
  }, 15000);
});
