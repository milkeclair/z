import fs from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { describe, expect, test } from 'vitest';
import {
  CompletionRequest,
  CompletionResolveRequest,
  DefinitionRequest,
  DocumentDiagnosticRequest,
  HoverRequest,
  SemanticTokensRequest,
  SignatureHelpRequest,
} from 'vscode-languageserver/node';
import { createLspClient, createProjectDirectory, withRequestTimeout } from './client';

describe('startServer', () => {
  describe('コード引数の編集支援を要求する場合', () => {
    test('code引数の診断を元の文字列へ返し、許可値と型アノテーションの編集を反映する', async () => {
      const root = createProjectDirectory();
      fs.writeFileSync(path.join(root, '.zshrc'), '');
      const definition = path.join(root, 'code.zsh');
      const definitionUri = pathToFileURL(definition).href;
      const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
      fs.writeFileSync(
        definition,
        '# $code? [code | \'call_original\']: commands\nrun_code() { print "$code" }\n',
      );
      const client = createLspClient({ env: { ...process.env, ZDOTDIR: root } });
      const request = () =>
        withRequestTimeout(
          client.connection.sendRequest(DocumentDiagnosticRequest.type, {
            textDocument: { uri: caller },
          }),
        );

      try {
        await client.initialize({ projectRoot: root, supportsRefresh: false });
        const source = "run_code code='fixture_embedded_missing'\n";
        await client.open(caller, source);

        expect(await request()).toMatchObject({
          items: [
            {
              code: 'undefined-command',
              range: { start: { line: 0, character: source.indexOf('fixture_embedded_missing') } },
            },
          ],
        });
        await client.edit(caller, 'run_code code=call_original\n', 2);

        expect(await request()).toMatchObject({ items: [] });
        await client.edit(caller, source, 3);
        await client.open(definitionUri, '# $code?: ordinary text\nrun_code() { print "$code" }\n');

        expect(await request()).toMatchObject({ items: [] });
      } finally {
        await client.close();
      }
    }, 15000);

    test('code引数内を実サーバーの補完・hover・署名・定義・色分けで編集する', async () => {
      const root = createProjectDirectory();
      const definitionFile = path.join(root, 'definition.zsh');
      const definitionUri = pathToFileURL(definitionFile).href;
      const uri = pathToFileURL(path.join(root, 'caller.zsh')).href;
      fs.writeFileSync(
        definitionFile,
        [
          "# $code? [code | 'noop']: commands",
          'run_code() { : }',
          '# Greeting',
          '# $1: value',
          'greet() { : }',
          '',
        ].join('\n'),
      );
      const client = createLspClient();

      try {
        const initialized = await client.initialize({ projectRoot: root, supportsRefresh: false });

        expect(initialized.capabilities.semanticTokensProvider).toMatchObject({
          full: true,
          legend: { tokenTypes: expect.arrayContaining(['function', 'variable', 'keyword']) },
        });
        const initialContent = "run_code code='gr'\n";
        await client.open(uri, initialContent);
        const items = await client.items(uri, initialContent.indexOf('gr') + 2);
        const item = items.find((item) => item.label === 'greet');

        expect(item).toMatchObject({
          textEdit: {
            newText: 'greet',
            range: {
              start: { line: 0, character: initialContent.indexOf('gr') },
              end: { line: 0, character: initialContent.indexOf('gr') + 2 },
            },
          },
        });

        const argumentContent = "run_code code='greet value'\n";
        await client.edit(uri, argumentContent, 2);
        const position = { line: 0, character: argumentContent.indexOf('greet') + 2 };

        expect(
          await withRequestTimeout(
            client.connection.sendRequest(HoverRequest.type, { textDocument: { uri }, position }),
          ),
        ).toMatchObject({ contents: { value: expect.stringContaining('Greeting') } });
        expect(
          await withRequestTimeout(
            client.connection.sendRequest(DefinitionRequest.type, {
              textDocument: { uri },
              position,
            }),
          ),
        ).toMatchObject({ uri: definitionUri });
        expect(
          await withRequestTimeout(
            client.connection.sendRequest(SignatureHelpRequest.type, {
              textDocument: { uri },
              position: { line: 0, character: argumentContent.indexOf('value') + 1 },
            }),
          ),
        ).toMatchObject({ signatures: [{ label: 'greet $1' }], activeParameter: 0 });
        expect(
          await withRequestTimeout(
            client.connection.sendRequest(HoverRequest.type, {
              textDocument: { uri },
              position: { line: 0, character: argumentContent.indexOf('code=') + 1 },
            }),
          ),
        ).toMatchObject({ contents: { value: expect.stringContaining("[code | 'noop']") } });
        const colors = await withRequestTimeout(
          client.connection.sendRequest(SemanticTokensRequest.type, { textDocument: { uri } }),
        );

        expect(colors?.data.length).toBeGreaterThan(0);

        await client.edit(uri, "run_code code='gr", 3);

        expect((await client.items(uri, 17)).map((item) => item.label)).toContain('greet');

        await client.edit(uri, 'run_code code=noop\n', 4);

        expect(
          await withRequestTimeout(
            client.connection.sendRequest(SemanticTokensRequest.type, { textDocument: { uri } }),
          ),
        ).toEqual({ data: [] });
        await client.edit(uri, "print 'greet'\n", 5);

        expect(
          await withRequestTimeout(
            client.connection.sendRequest(SemanticTokensRequest.type, { textDocument: { uri } }),
          ),
        ).toEqual({ data: [] });

        const localContent = "run_code code='inner() { : }; inner'\ninner\n";
        await client.edit(uri, localContent, 6);
        const innerPosition = { line: 0, character: localContent.lastIndexOf("inner'") + 2 };
        const localItems = await withRequestTimeout(
          client.connection.sendRequest(CompletionRequest.type, {
            textDocument: { uri },
            position: innerPosition,
          }),
        );
        const localItem = (Array.isArray(localItems) ? localItems : (localItems?.items ?? [])).find(
          (item) => item.label === 'inner',
        );

        if (!localItem) {
          throw new Error('inner completion required');
        }

        const resolved = await withRequestTimeout(
          client.connection.sendRequest(CompletionResolveRequest.type, localItem),
        );

        expect(resolved.detail).not.toContain('#code:');
        expect(
          await withRequestTimeout(
            client.connection.sendRequest(DefinitionRequest.type, {
              textDocument: { uri },
              position: innerPosition,
            }),
          ),
        ).toMatchObject({
          uri,
          range: { start: { line: 0, character: localContent.indexOf('inner') } },
        });
        const outside = await withRequestTimeout(
          client.connection.sendRequest(CompletionRequest.type, {
            textDocument: { uri },
            position: { line: 1, character: 5 },
          }),
        );

        expect(
          (Array.isArray(outside) ? outside : (outside?.items ?? [])).map((item) => item.label),
        ).not.toContain('inner');
      } finally {
        await client.close();
      }
    }, 15000);
  });
});
