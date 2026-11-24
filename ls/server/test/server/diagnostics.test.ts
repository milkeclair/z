import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { describe, expect, test } from 'vitest';
import {
  DidChangeWatchedFilesNotification,
  DocumentDiagnosticRequest,
  FileChangeType,
  HoverRequest,
  SignatureHelpRequest,
  WorkspaceDiagnosticRequest,
} from 'vscode-languageserver/node';
import { writeClassApi } from '../support/classApi';
import { createLspClient, createProjectDirectory, withRequestTimeout } from './client';

describe('startServer', () => {
  describe('診断を取得する場合', () => {
    test('.zshrcが読み込んだプロジェクト外の引数契約でselfを診断する', async () => {
      const root = createProjectDirectory();
      const outside = createProjectDirectory();
      const library = path.join(outside, 'shared functions');
      fs.writeFileSync(
        library,
        '# $1 [Counter<write>]: 更新するインスタンス\nexternal_update() { $1.count.set 1; }\n',
      );
      fs.writeFileSync(path.join(outside, '.zshrc'), 'source ' + JSON.stringify(library) + '\n');
      writeClassApi(root);

      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      const source = [
        'z.cls.draw Counter',
        '  z.cls.attr count default=0',
        '  # $self [Counter<read>]: 読み取るインスタンス',
        '  z.cls.method value',
        '    external_update "$self"',
        '  z.cls.method.defined',
        'z.cls.drew',
        '',
      ].join('\n');
      const client = createLspClient({ env: { ...process.env, ZDOTDIR: outside } });
      const request = () =>
        withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: caller },
          }),
        );

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        await client.open(caller, source);

        expect(await request()).toMatchObject({
          kind: 'full',
          items: [
            {
              code: 'class-argument-type',
              range: { start: { line: 4 } },
              message: 'Expected Counter<write> for self, received Counter<read>.',
            },
          ],
        });

        fs.writeFileSync(
          library,
          '# $1 [Counter<read>]: 読み取るインスタンス\nexternal_update() { $1.count.get; }\n',
        );
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [{ uri: pathToFileURL(library).href, type: FileChangeType.Changed }],
        });
        await expect.poll(request).toMatchObject({ kind: 'full', items: [] });
      } finally {
        await client.close();
      }
    }, 15000);

    test('引用した名前付き引数の診断・署名・hoverを実サーバーで返す', async () => {
      const root = createProjectDirectory();
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      fs.writeFileSync(
        path.join(root, 'definition.zsh'),
        [
          '# $1: first',
          '# $message: error message',
          'z.t._log.failure.handle() { print "$1" "$message" }',
          '',
        ].join('\n'),
      );
      const client = createLspClient();
      const source =
        'z.t._log.failure.handle "message=failed: expected [ $expect_display ] but got [ $actual_display ]" first\n';
      const request = () =>
        withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: caller },
          }),
        );

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        await client.open(caller, source);

        expect(await request()).toMatchObject({ kind: 'full', items: [] });
        const position = { line: 0, character: source.indexOf('expected') };

        expect(
          await withRequestTimeout(
            client.connection.sendRequest(SignatureHelpRequest.type, {
              textDocument: { uri: caller },
              position,
            }),
          ),
        ).toMatchObject({ activeParameter: 1, signatures: [{ activeParameter: 1 }] });
        expect(
          await withRequestTimeout(
            client.connection.sendRequest(HoverRequest.type, {
              textDocument: { uri: caller },
              position,
            }),
          ),
        ).toMatchObject({ contents: { value: expect.stringContaining('error message') } });
        await client.edit(caller, 'z.t._log.failure.handle first\n', 2);

        expect(await request()).toMatchObject({
          kind: 'full',
          items: [
            {
              code: 'missing-named-argument',
              message: 'Missing required named argument: message',
            },
          ],
        });
      } finally {
        await client.close();
      }
    }, 15000);

    test('AST診断・環境解決・抑制・依存先変更を実サーバーで反映する', async () => {
      const root = createProjectDirectory();
      const definition = path.join(root, 'definition.zsh');
      const definitionUri = pathToFileURL(definition).href;
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      fs.mkdirSync(path.join(root, 'bin'));
      fs.writeFileSync(path.join(root, 'bin', 'fixture-protocol-command'), '#!/bin/sh\nexit 0\n', {
        mode: 0o755,
      });
      fs.writeFileSync(
        path.join(root, '.zshrc'),
        [
          'path=(' + JSON.stringify(path.join(root, 'bin')) + ' $path)',
          "alias fixture-protocol-alias='print value'",
          'autoload -Uz fixture-protocol-autoload',
        ].join('\n'),
      );
      fs.writeFileSync(definition, '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n');
      const client = createLspClient({ env: { ...process.env, ZDOTDIR: root } });
      const request = () =>
        withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: caller },
          }),
        );

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        await client.open(
          caller,
          'greet "hello\nworld"\nfixture-protocol-command\nfixture-protocol-alias\nfixture-protocol-autoload\n',
        );

        expect(await request()).toMatchObject({
          kind: 'full',
          items: [
            { code: 'missing-positional-argument', message: 'Missing required argument(s): $2' },
          ],
        });
        await client.open(definitionUri, '# $1: first\ngreet() { print "$1" }\n');

        expect(await request()).toMatchObject({ kind: 'full', items: [] });
        await client.edit(caller, 'greet # zls: ignore\nfixture-unresolved-command\n', 2);

        expect(await request()).toMatchObject({
          items: [{ code: 'undefined-command', range: { start: { line: 1, character: 0 } } }],
        });
        await client.edit(caller, 'greet # zls: ignore\n', 3);

        expect(await request()).toMatchObject({ items: [] });
        const removed = path.join(root, 'removed.zsh');
        const removedUri = pathToFileURL(removed).href;
        fs.writeFileSync(removed, 'fixture-unresolved-command\n');
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [{ uri: removedUri, type: FileChangeType.Created }],
        });
        const workspace = await withRequestTimeout(
          client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }),
        );

        expect(workspace.items.find((item) => item.uri === removedUri)).toMatchObject({
          version: null,
          items: [{ code: 'undefined-command' }],
        });
        expect(workspace.items.find((item) => item.uri === caller)).toMatchObject({
          version: 3,
          items: [],
        });
        const previous = workspace.items.find((item) => item.uri === removedUri);

        if (!previous?.resultId) {
          throw new Error('workspace resultId required');
        }

        fs.unlinkSync(removed);
        await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, {
          changes: [{ uri: removedUri, type: FileChangeType.Deleted }],
        });
        const deleted = await withRequestTimeout(
          client.connection.sendRequest(WorkspaceDiagnosticRequest.type, {
            previousResultIds: [{ uri: removedUri, value: previous.resultId }],
          }),
        );

        expect(deleted.items.find((item) => item.uri === removedUri)).toMatchObject({
          version: null,
          items: [],
        });
      } finally {
        await client.close();
      }
    }, 15000);

    test('moduleの読み込み宣言を編集すると未編集文書の診断も更新する', async () => {
      const root = createProjectDirectory();
      fs.writeFileSync(path.join(root, '.zshrc'), '');
      const declaration = path.join(root, 'module.zsh');
      const declarationUri = pathToFileURL(declaration).href;
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      fs.writeFileSync(declaration, 'zmodload zsh/zpty\n');
      const client = createLspClient({ env: { ...process.env, ZDOTDIR: root } });
      const request = () =>
        withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: caller },
          }),
        );

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        await client.open(caller, 'zpty\n');

        expect(await request()).toMatchObject({ items: [] });
        await client.open(declarationUri, 'zmodload zsh/zpty\n');
        await client.edit(declarationUri, '', 2);

        expect(await request()).toMatchObject({ items: [{ code: 'undefined-command' }] });
        await client.edit(declarationUri, 'zmodload zsh/zpty\n', 3);

        expect(await request()).toMatchObject({ items: [] });
        const workspace = await withRequestTimeout(
          client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }),
        );

        expect(workspace.items.find((item) => item.uri === caller)).toMatchObject({
          version: 1,
          items: [],
        });
      } finally {
        await client.close();
      }
    }, 15000);
  });
});
