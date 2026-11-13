import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawn } from 'node:child_process';
import {
  createProtocolConnection, InitializeRequest, InitializedNotification,
  ShutdownRequest, ExitNotification, RegistrationRequest, CompletionRequest,
  CompletionResolveRequest, HoverRequest, SignatureHelpRequest, DocumentDiagnosticRequest,
  DidOpenTextDocumentNotification, DidChangeTextDocumentNotification,
  DidSaveTextDocumentNotification, DidCloseTextDocumentNotification,
  DidChangeWatchedFilesNotification, DidChangeConfigurationNotification, FileChangeType,
} from 'vscode-languageserver/node';
import type { InitializeParams, CompletionItem } from 'vscode-languageserver/node';

const roots: string[] = [];
function fixture(): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-lsp-stdio-'));
  roots.push(root);
  return root;
}
afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});

async function bounded<T>(promise: Promise<T>): Promise<T> {
  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    return await Promise.race([promise, new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error('LSP request timed out')), 5000);
    })]);
  } finally {
    clearTimeout(timer);
  }
}

function startServer() {
  const child = spawn(process.execPath, [path.resolve(__dirname, '../../dist/server.js'), '--stdio'], {
    stdio: 'pipe',
  });
  let stderr = '';
  child.stderr.on('data', (data: Buffer) => { stderr += data.toString(); });
  const exited = new Promise<number | null>((resolve) => {
    child.once('exit', (code) => resolve(code));
  });
  const connection = createProtocolConnection(child.stdout, child.stdin);
  const registrations: string[] = [];
  const refreshRequests: string[] = [];
  connection.onRequest(RegistrationRequest.type, (params) => {
    registrations.push(...params.registrations.map(registration => registration.method));
  });
  connection.onRequest('workspace/diagnostic/refresh', () => { refreshRequests.push('refresh'); });
  connection.listen();
  return {
    connection, registrations, refreshRequests,
    async initialize(root: string, refreshSupport: boolean, workspace = true) {
      const params: InitializeParams = {
        processId: null, rootUri: workspace ? pathToFileURL(root).href : null,
        workspaceFolders: workspace ? [{ name: 'fixture', uri: pathToFileURL(root).href }] : null,
        capabilities: { workspace: {
          didChangeWatchedFiles: { dynamicRegistration: refreshSupport },
          diagnostics: { refreshSupport },
        } },
        initializationOptions: { zPath: workspace ? path.join(root, 'unused-legacy-root') : root },
      };
      const result = await bounded(connection.sendRequest(InitializeRequest.type, params));
      await connection.sendNotification(InitializedNotification.type, {});
      return result;
    },
    async open(uri: string, content: string, version = 1) {
      await connection.sendNotification(DidOpenTextDocumentNotification.type, {
        textDocument: { uri, version, languageId: 'shellscript', text: content },
      });
    },
    async edit(uri: string, content: string, version: number) {
      await connection.sendNotification(DidChangeTextDocumentNotification.type, {
        textDocument: { uri, version }, contentChanges: [{ text: content }],
      });
    },
    async items(uri: string, character = 2): Promise<CompletionItem[]> {
      const result = await bounded(connection.sendRequest(CompletionRequest.type, {
        textDocument: { uri }, position: { line: 0, character },
      }));
      return Array.isArray(result) ? result : result?.items ?? [];
    },
    async close() {
      try {
        if (child.exitCode === null) {
          await bounded(connection.sendRequest(ShutdownRequest.type));
          await connection.sendNotification(ExitNotification.type);
        }
        const code = await bounded(exited);
        expect(code, stderr).toBe(0);
        expect(stderr).toBe('');
      } finally {
        connection.dispose();
        if (child.exitCode === null) child.kill('SIGKILL');
        await bounded(exited);
      }
    },
  };
}

describe('server@hydration stdio', () => {

  test('workspaceのない接続は設定変更で解析対象を切り替える', async () => {
    const first = fixture();
    const second = fixture();
    fs.writeFileSync(path.join(first, 'functions.zsh'), 'z.first() { : }\n');
    fs.writeFileSync(path.join(second, 'functions.zsh'), 'z.second() { : }\n');
    const uri = pathToFileURL(path.join(first, 'caller.zsh')).href;
    const client = startServer();
    try {
      await client.initialize(first, false, false);
      await client.open(uri, 'z.');
      expect((await client.items(uri)).map(item => item.label)).toEqual(['z.first']);
      await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
        settings: { 'z-ls': { zPath: second } },
      });
      expect((await client.items(uri)).map(item => item.label)).toEqual(['z.second']);
      await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
        settings: { 'z-ls': { zPath: '' } },
      });
      expect(await client.items(uri)).toEqual([]);
    } finally {
      await client.close();
    }
  }, 15000);

  test('文書イベントを処理し、編集直後の関数・文書情報とdiskの復元を返す', async () => {
    const root = fixture();
    const definition = path.join(root, 'functions.zsh');
    const definitionUri = pathToFileURL(definition).href;
    const callerUri = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(definition, '# Disk docs\n# $1: disk\nz.disk() { print "$1" }\n');
    const client = startServer();
    try {
      const initialized = await client.initialize(root, true);
      expect(initialized.capabilities.textDocumentSync).toMatchObject({ save: true });
      await client.open(callerUri, 'z.');
      expect((await client.items(callerUri)).map(item => item.label)).toContain('z.disk');

      await client.open(definitionUri, '# Live docs\n# $1: unsaved\nz.live() { print "$1" }\n');
      const items = await client.items(callerUri);
      expect(items.map(item => item.label)).toContain('z.live');
      expect(items.map(item => item.label)).not.toContain('z.disk');
      const live = items.find(item => item.label === 'z.live');
      if (!live) throw new Error('live completion required');
      expect(live.data).toMatchObject({ line: 3, args: [{ name: 'unsaved', position: 1 }] });
      const resolved = await bounded(client.connection.sendRequest(CompletionResolveRequest.type, live));
      expect(resolved.documentation).toMatchObject({ value: expect.stringContaining('Live docs') });

      await client.edit(callerUri, 'z.live', 2);
      await client.edit(definitionUri, '# Edited docs\n# $1: edited\nz.live() { print "$1" }\n', 2);
      const hovered = await bounded(client.connection.sendRequest(HoverRequest.type, {
        textDocument: { uri: callerUri }, position: { line: 0, character: 4 },
      }));
      expect(hovered).toMatchObject({ contents: { value: expect.stringContaining('Edited docs') } });

      await client.edit(callerUri, 'z.live ', 3);
      const signature = await bounded(client.connection.sendRequest(SignatureHelpRequest.type, {
        textDocument: { uri: callerUri }, position: { line: 0, character: 7 },
      }));
      expect(signature).toMatchObject({ signatures: [{ parameters: [
        { documentation: { value: 'edited' } },
      ] }] });

      const extra = path.join(root, 'extra.zsh');
      fs.writeFileSync(extra, 'z.extra() { : }\n');
      fs.writeFileSync(definition, 'z.saved() { : }\n');
      await client.connection.sendNotification(DidSaveTextDocumentNotification.type, {
        textDocument: { uri: definitionUri },
      });
      await client.edit(callerUri, 'z.', 4);
      expect((await client.items(callerUri)).map(item => item.label)).toEqual(['z.extra', 'z.live']);

      await client.connection.sendNotification(DidCloseTextDocumentNotification.type, {
        textDocument: { uri: definitionUri },
      });
      expect((await client.items(callerUri)).map(item => item.label)).toEqual(['z.extra', 'z.saved']);
      const stale = await bounded(client.connection.sendRequest(CompletionResolveRequest.type, live));
      expect(stale.documentation).toBeUndefined();


      fs.unlinkSync(extra);
      const watched = path.join(root, 'watched.zsh');
      fs.writeFileSync(watched, 'z.watched() { : }\n');
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, { changes: [
        { uri: pathToFileURL(extra).href, type: FileChangeType.Deleted },
        { uri: pathToFileURL(watched).href, type: FileChangeType.Created },
      ] });
      expect((await client.items(callerUri)).map(item => item.label)).toEqual(['z.saved', 'z.watched']);
      const diagnostic = await bounded(client.connection.sendRequest(DocumentDiagnosticRequest.type, {
        textDocument: { uri: callerUri },
      }));
      expect(diagnostic).toMatchObject({ kind: 'full', items: expect.any(Array) });
      await expect.poll(() => client.refreshRequests.length).toBeGreaterThan(0);
      expect(client.registrations).toEqual(['workspace/didChangeWatchedFiles']);
    } finally {
      await client.close();
    }
  }, 15000);

  test('一般名の新規buffer・workspace境界と任意capabilityのないクライアントを扱う', async () => {
    const root = fixture();
    const uri = pathToFileURL(path.join(root, 'new.zsh')).href;
    const outside = pathToFileURL(path.join(path.dirname(root), 'outside.zsh')).href;
    const client = startServer();
    try {
      await client.initialize(root, false);
      await client.open(uri, '# New docs\ngreet() { : }\n');
      await client.open(outside, 'z.outside() { : }\n');
      await client.edit(uri, 'gre\n# New docs\ngreet() { : }\n', 2);
      const items = await client.items(uri, 3);
      expect(items.map(item => item.label)).toEqual(['greet']);
      expect(items[0].textEdit).toMatchObject({ range: {
        start: { line: 0, character: 0 }, end: { line: 0, character: 3 },
      }, newText: 'greet' });
      const hovered = await bounded(client.connection.sendRequest(HoverRequest.type, {
        textDocument: { uri }, position: { line: 0, character: 2 },
      }));
      const resolved = await bounded(client.connection.sendRequest(CompletionResolveRequest.type, items[0]));
      expect(resolved.documentation).toMatchObject({ value: expect.stringContaining('New docs') });
      expect(hovered).toBeNull();
      await client.edit(uri, 'greet\n# New docs\ngreet() { : }\n', 3);
      const fullHover = await bounded(client.connection.sendRequest(HoverRequest.type, {
        textDocument: { uri }, position: { line: 0, character: 2 },
      }));
      expect(fullHover).toMatchObject({ contents: { value: expect.stringContaining('New docs') } });
      await client.connection.sendNotification(DidChangeConfigurationNotification.type, {
        settings: { 'z-ls': { zPath: path.join(root, 'ignored'), completion: { showPrivateFunctions: true } } },
      });
      expect((await client.items(uri, 3)).map(item => item.label)).toEqual(['greet']);
      await new Promise(resolve => setTimeout(resolve, 650));
      expect(client.registrations).toEqual([]);
      expect(client.refreshRequests).toEqual([]);
    } finally {
      await client.close();
    }
  }, 15000);
});
