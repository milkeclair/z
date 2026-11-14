import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { spawn } from 'node:child_process';
import {
  createProtocolConnection, InitializeRequest, InitializedNotification,
  ShutdownRequest, ExitNotification, RegistrationRequest, CompletionRequest,
  CompletionResolveRequest, HoverRequest, SignatureHelpRequest, DefinitionRequest, DocumentDiagnosticRequest, WorkspaceDiagnosticRequest,
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

function startServer(env?: NodeJS.ProcessEnv, rejectWatchRegistration = false, preload?: string) {
  const child = spawn(process.execPath, [...(preload ? ['--require', preload] : []), path.resolve(__dirname, '../../dist/server.js'), '--stdio'], {
    stdio: 'pipe', env,
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
    if (rejectWatchRegistration) throw new Error('watch registration rejected by client');
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

function observedServer(root: string) {
  const filename = path.join(root, 'parsed.json');
  const preload = path.join(root, 'observe.cjs');
  fs.writeFileSync(filename, '[]');
  fs.writeFileSync(preload, [
    "const fs = require('node:fs');",
    'const hydration = require(' + JSON.stringify(path.resolve(__dirname, '../../dist/zshHydrator/fileHydration.js')) + ');',
    'const original = hydration.createZshFileHydration;',
    'const parsed = [];',
    'hydration.createZshFileHydration = input => {',
    '  const result = original(input);',
    '  parsed.push({ sourceFile: input.sourceFile, content: input.content });',
    '  fs.writeFileSync(' + JSON.stringify(filename) + ', JSON.stringify(parsed));',
    '  return result;',
    '};',
  ].join('\n'));
  return { client: startServer(undefined, false, preload), parsed: () => fs.readFileSync(filename, 'utf8') };
}

function periodicServer(root: string) {
  const filename = path.join(root, 'ticks.log');
  const preload = path.join(root, 'periodic-clock.cjs');
  fs.writeFileSync(filename, '');
  fs.writeFileSync(preload, [
    "const fs = require('node:fs');",
    'const original = global.setInterval;',
    'global.setInterval = (callback, delay, ...args) => {',
    '  if (delay !== 60000) return original(callback, delay, ...args);',
    '  return original(() => {',
    '    try { callback(...args); }',
    '    finally { fs.appendFileSync(' + JSON.stringify(filename) + ', "tick\\n"); }',
    '  }, 100);',
    '};',
  ].join('\n'));
  return { client: startServer(undefined, false, preload), ticks: () => fs.readFileSync(filename, 'utf8').length };
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
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, { changes: [
        { uri: pathToFileURL(extra).href, type: FileChangeType.Created },
      ] });
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
  test('一般名の呼び出し・複数行引数・正確な定義位置を実サーバーで返す', async () => {
    const root = fixture();
    const definition = path.join(root, '日本語 name.zsh');
    const definitionUri = pathToFileURL(definition).href;
    fs.writeFileSync(definition, '# Greeting\n# $1: first\n# $2: second\n  function greet { : }\n');
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    const client = startServer();
    try {
      await client.initialize(root, false);
      await client.open(caller, 'greet "hello\nworld" ');
      const signature = await bounded(client.connection.sendRequest(SignatureHelpRequest.type, {
        textDocument: { uri: caller }, position: { line: 1, character: 7 },
      }));
      expect(signature).toMatchObject({ activeParameter: 1,
        signatures: [{ parameters: [
          { documentation: { value: 'first' } }, { documentation: { value: 'second' } },
        ] }] });
      const location = await bounded(client.connection.sendRequest(DefinitionRequest.type, {
        textDocument: { uri: caller }, position: { line: 0, character: 2 },
      }));
      expect(location).toEqual({ uri: definitionUri, range: {
        start: { line: 3, character: 11 }, end: { line: 3, character: 16 },
      } });
      for (const [version, text] of ['print "greet"', '# greet', 'print > greet', 'builtin greet'].entries()) {
        await client.edit(caller, text, version + 2);
        const character = text.indexOf('greet') + 2;
        expect(await bounded(client.connection.sendRequest(DefinitionRequest.type, {
          textDocument: { uri: caller }, position: { line: 0, character },
        }))).toBeNull();
        expect(await bounded(client.connection.sendRequest(HoverRequest.type, {
          textDocument: { uri: caller }, position: { line: 0, character },
        }))).toBeNull();
      }
      await client.edit(caller, 'print "$(greet x )"', 7);
      expect(await bounded(client.connection.sendRequest(SignatureHelpRequest.type, {
        textDocument: { uri: caller }, position: { line: 0, character: 17 },
      }))).toMatchObject({ activeParameter: 1 });
    } finally {
      await client.close();
    }
  }, 15000);

  test('AST診断・環境解決・抑制・依存先変更を実サーバーで反映する', async () => {
    const root = fixture();
    const definition = path.join(root, 'definition.zsh');
    const definitionUri = pathToFileURL(definition).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.mkdirSync(path.join(root, 'bin'));
    fs.writeFileSync(path.join(root, 'bin', 'fixture-protocol-command'), '#!/bin/sh\nexit 0\n', { mode: 0o755 });
    fs.writeFileSync(path.join(root, '.zshrc'), [
      'path=(' + JSON.stringify(path.join(root, 'bin')) + ' $path)',
      "alias fixture-protocol-alias='print value'", 'autoload -Uz fixture-protocol-autoload',
    ].join('\n'));
    fs.writeFileSync(definition, '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n');
    const client = startServer({ ...process.env, ZDOTDIR: root });
    const request = () => bounded(client.connection.sendRequest(DocumentDiagnosticRequest.type, {
      textDocument: { uri: caller },
    }));
    try {
      await client.initialize(root, false);
      await client.open(caller, 'greet "hello\nworld"\nfixture-protocol-command\nfixture-protocol-alias\nfixture-protocol-autoload\n');
      expect(await request()).toMatchObject({ kind: 'full', items: [
        { code: 'missing-positional-argument', message: 'Missing required argument(s): $2' },
      ] });
      await client.open(definitionUri, '# $1: first\ngreet() { print "$1" }\n');
      expect(await request()).toMatchObject({ kind: 'full', items: [] });
      await client.edit(caller, 'greet # zls: ignore\nfixture-unresolved-command\n', 2);
      expect(await request()).toMatchObject({ items: [
        { code: 'undefined-command', range: { start: { line: 1, character: 0 } } },
      ] });
      await client.edit(caller, 'greet # zls: ignore\n', 3);
      expect(await request()).toMatchObject({ items: [] });
      const removed = path.join(root, 'removed.zsh');
      const removedUri = pathToFileURL(removed).href;
      fs.writeFileSync(removed, 'fixture-unresolved-command\n');
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, { changes: [
        { uri: removedUri, type: FileChangeType.Created },
      ] });
      const workspace = await bounded(client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }));
      expect(workspace.items.find(item => item.uri === removedUri)).toMatchObject({
        version: null, items: [{ code: 'undefined-command' }],
      });
      expect(workspace.items.find(item => item.uri === caller)).toMatchObject({ version: 3, items: [] });
      const previous = workspace.items.find(item => item.uri === removedUri);
      if (!previous?.resultId) throw new Error('workspace resultId required');
      fs.unlinkSync(removed);
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, { changes: [
        { uri: removedUri, type: FileChangeType.Deleted },
      ] });
      const deleted = await bounded(client.connection.sendRequest(WorkspaceDiagnosticRequest.type, {
        previousResultIds: [{ uri: removedUri, value: previous.resultId }],
      }));
      expect(deleted.items.find(item => item.uri === removedUri)).toMatchObject({ version: null, items: [] });
    } finally {
      await client.close();
    }
  }, 15000);

  test.each(['unsupported', 'rejected', 'no-workspace'])('watcherが%sなら文書更新時の全走査でdisk変更を同期する', async mode => {
    const root = fixture();
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    const client = startServer(undefined, mode === 'rejected');
    try {
      await client.initialize(root, mode !== 'unsupported', mode !== 'no-workspace');
      await client.open(caller, 'gre');
      await client.items(caller, 3);
      fs.writeFileSync(path.join(root, 'added.zsh'), 'greet() { : }\n');
      await client.edit(caller, 'gree', 2);
      expect((await client.items(caller, 4)).map(item => item.label)).toEqual(['greet']);
      fs.unlinkSync(path.join(root, 'added.zsh'));
      await client.edit(caller, 'gre', 3);
      expect(await client.items(caller, 3)).toEqual([]);
      expect(client.registrations).toEqual(mode !== 'unsupported' ? ['workspace/didChangeWatchedFiles'] : []);
    } finally { await client.close(); }
  }, 15000);

  test('watcher利用時は編集で未知のdiskを走査せず、通知・save・closeで対象だけ反映する', async () => {
    const root = fixture();
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    const definition = path.join(root, 'a.zsh');
    const uri = pathToFileURL(definition).href;
    const client = startServer();
    try {
      await client.initialize(root, true);
      await client.open(caller, 'z.');
      await client.items(caller);
      // Observe a refresh after registration to establish the incremental path.
      await expect.poll(() => client.refreshRequests.length).toBeGreaterThan(0);
      fs.writeFileSync(definition, 'z.disk() { : }\n');
      await client.edit(caller, 'z.d', 2);
      expect(await client.items(caller, 3)).toEqual([]);
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, { changes: [
        { uri, type: FileChangeType.Created },
      ] });
      expect((await client.items(caller, 3)).map(item => item.label)).toEqual(['z.disk']);
      await client.open(uri, 'z.live() { : }\n');
      await client.edit(caller, 'z.', 3);
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.live']);
      fs.writeFileSync(definition, 'z.saved() { : }\n');
      await client.connection.sendNotification(DidSaveTextDocumentNotification.type, { textDocument: { uri } });
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.live']);
      fs.unlinkSync(definition);
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type, { changes: [
        { uri, type: FileChangeType.Deleted },
        { uri: 'untitled:ignored.zsh', type: FileChangeType.Created },
      ] });
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.live']);
      await client.connection.sendNotification(DidCloseTextDocumentNotification.type, { textDocument: { uri } });
      expect(await client.items(caller)).toEqual([]);
    } finally { await client.close(); }
  }, 15000);

  test('連続編集を最新内容の一回の解析へまとめ、補完要求では待機せず反映する', async () => {
    const root = fixture();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(filename, 'greet_old() { : }\n');
    const { client, parsed } = observedServer(root);
    try {
      await client.initialize(root, true);
      await client.open(uri, 'greet_old() { : }\n');
      await client.open(caller, 'greet_');
      await client.items(caller, 6);
      const before = parsed();
      for (let version = 2; version <= 101; version++) {
        await client.edit(uri, '# Version ' + version + '\ngreet_final() { : }\n', version);
      }
      expect((await client.items(caller, 6)).map(item => item.label)).toEqual(['greet_final']);
      const additions = parsed().slice(before.length - 1);
      expect(additions.match(/greet_final/g)).toHaveLength(1);
      expect(additions).toContain('Version 101');
    } finally { await client.close(); }
  }, 15000);

  test('要求がなくても待機後に最新bufferを解析する', async () => {
    const root = fixture();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    fs.writeFileSync(filename, 'old() { : }\n');
    const { client, parsed } = observedServer(root);
    try {
      await client.initialize(root, false);
      await client.open(uri, 'old() { : }\n');
      await client.items(uri);
      const before = parsed();
      for (let version = 2; version <= 101; version++) {
        await client.edit(uri, '# Version ' + version + '\nquiet_latest() { : }\n', version);
      }
      await expect.poll(() => parsed().slice(before.length - 1).match(/quiet_latest/g)?.length ?? 0).toBe(1);
      expect(parsed()).toContain('Version 101');
    } finally { await client.close(); }
  }, 15000);

  test('各providerは保留中の編集を反映し、save/closeは複数のdisk通知も引き継ぐ', async () => {
    const root = fixture();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    const initial = '# First docs\n# $1: first\ngreet() { print "$1" }\n';
    fs.writeFileSync(filename, initial);
    const client = startServer();
    try {
      await client.initialize(root, true);
      await client.open(uri, initial);
      await client.open(caller, 'gre');
      const completion = (await client.items(caller, 3)).find(item => item.label === 'greet');
      if (!completion) throw new Error('greet completion required');
      const later = initial.replace('First', 'Later');
      await client.edit(uri, later, 2);
      expect(await bounded(client.connection.sendRequest(CompletionResolveRequest.type, completion)))
        .toMatchObject({ documentation: { value: expect.stringContaining('Later docs') } });
      await client.edit(uri, '\n' + later, 3);
      await client.edit(caller, 'greet one\n', 2);
      const params = { textDocument: { uri: caller }, position: { line: 0, character: 2 } };
      expect(await bounded(client.connection.sendRequest(DefinitionRequest.type, params)))
        .toMatchObject({ uri, range: { start: { line: 3 } } });
      const fresh = '\n' + later.replace('Later', 'Fresh');
      await client.edit(uri, fresh, 4);
      expect(await bounded(client.connection.sendRequest(HoverRequest.type, params)))
        .toMatchObject({ contents: { value: expect.stringContaining('Fresh docs') } });
      await client.edit(uri, fresh.replace('$1: first', '$2: second'), 5);
      expect(await bounded(client.connection.sendRequest(DocumentDiagnosticRequest.type, { textDocument: { uri: caller } })))
        .toMatchObject({ items: [{ code: 'missing-positional-argument', message: 'Missing required argument(s): $2' }] });
      const newest = fresh.replace('$1: first', '$1: newest');
      await client.edit(uri, newest, 6);
      await client.edit(caller, 'greet ', 3);
      expect(await bounded(client.connection.sendRequest(SignatureHelpRequest.type,
        { textDocument: { uri: caller }, position: { line: 0, character: 6 } })))
        .toMatchObject({ signatures: [{ parameters: [{ documentation: { value: 'newest' } }] }] });
      await client.edit(uri, newest + 'fixture_debounce_never_defined\n', 7);
      const workspace = await bounded(client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }));
      expect(workspace.items.find(item => item.uri === uri))
        .toMatchObject({ version: 7, items: [{ code: 'empty-line' }, { code: 'undefined-command' }] });

      const watched = path.join(root, 'watched.zsh');
      fs.writeFileSync(watched, 'watch_merged() { : }\n');
      await client.connection.sendNotification(DidChangeWatchedFilesNotification.type,
        { changes: [{ uri: pathToFileURL(watched).href, type: FileChangeType.Created }] });
      await client.edit(uri, 'greet_live() { : }\n', 8);
      await client.connection.sendNotification(DidSaveTextDocumentNotification.type, { textDocument: { uri } });
      await client.edit(caller, 'watch_', 4);
      expect((await client.items(caller, 6)).map(item => item.label)).toEqual(['watch_merged']);
      await client.edit(uri, 'greet_pending() { : }\n', 9);
      fs.writeFileSync(filename, 'greet_disk() { : }\n');
      await client.connection.sendNotification(DidCloseTextDocumentNotification.type, { textDocument: { uri } });
      await client.edit(caller, 'greet_', 5);
      expect((await client.items(caller, 6)).map(item => item.label)).toEqual(['greet_disk']);
    } finally { await client.close(); }
  }, 15000);

  test('shutdown時に保留中の解析を破棄し、タイマーを残さず終了する', async () => {
    const root = fixture();
    const filename = path.join(root, 'definitions.zsh');
    const uri = pathToFileURL(filename).href;
    fs.writeFileSync(filename, 'old() { : }\n');
    const { client, parsed } = observedServer(root);
    try {
      await client.initialize(root, false);
      await client.open(uri, 'old() { : }\n');
      await client.items(uri);
      const before = parsed();
      await client.edit(uri, 'discarded_on_shutdown() { : }\n', 2);
      await client.close();
      expect(parsed()).toBe(before);
    } finally { await client.close(); }
  }, 15000);

  test('定期走査で通知されなかったdiskの追加・変更・削除・renameと診断を同期する', async () => {
    const root = fixture();
    const first = path.join(root, 'first.zsh');
    const added = path.join(root, 'added.zsh');
    const renamed = path.join(root, 'renamed.zsh');
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(first, 'z.original() { : }\n');
    const { client, ticks } = periodicServer(root);
    try {
      await client.initialize(root, true);
      await client.open(caller, 'z.');
      await client.items(caller);
      await expect.poll(ticks, { timeout: 1500 }).toBeGreaterThan(0);
      fs.writeFileSync(first, 'z.changed() { : }\n');
      fs.writeFileSync(added, 'z.added() { : }\nfixture_periodic_unknown\n');
      const before = ticks();
      await expect.poll(ticks).toBeGreaterThan(before);
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.added', 'z.changed']);
      fs.renameSync(added, renamed);
      fs.unlinkSync(first);
      const moved = ticks();
      await expect.poll(ticks).toBeGreaterThan(moved);
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.added']);
      const workspace = await bounded(client.connection.sendRequest(WorkspaceDiagnosticRequest.type, { previousResultIds: [] }));
      expect(workspace.items.find(item => item.uri === pathToFileURL(renamed).href))
        .toMatchObject({ version: null, items: [{ code: 'undefined-command' }] });
      expect(workspace.items.some(item => item.uri === pathToFileURL(first).href)).toBe(false);
    } finally { await client.close(); }
  }, 15000);

  test('定期走査中も未保存bufferを優先し、closeで更新後のdiskへ戻す', async () => {
    const root = fixture();
    const filename = path.join(root, 'definition.zsh');
    const uri = pathToFileURL(filename).href;
    const caller = pathToFileURL(path.join(root, 'caller.zsh')).href;
    fs.writeFileSync(filename, 'z.disk() { : }\n');
    const { client, ticks } = periodicServer(root);
    try {
      await client.initialize(root, true);
      await client.open(uri, '# Unsaved docs\nz.live() { : }\n');
      await client.open(caller, 'z.');
      await client.items(caller);
      fs.writeFileSync(filename, 'z.saved() { : }\n');
      const before = ticks();
      await expect.poll(ticks).toBeGreaterThan(before);
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.live']);
      await client.connection.sendNotification(DidCloseTextDocumentNotification.type, { textDocument: { uri } });
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.saved']);
    } finally { await client.close(); }
  }, 15000);

  test('定期走査は設定変更後のrootを参照し、project未選択なら走査を休止する', async () => {
    const first = fixture();
    const second = fixture();
    fs.writeFileSync(path.join(first, 'first.zsh'), 'z.first() { : }\n');
    fs.writeFileSync(path.join(second, 'second.zsh'), 'z.second() { : }\n');
    const caller = pathToFileURL(path.join(first, 'caller.zsh')).href;
    const { client, ticks } = periodicServer(first);
    try {
      await client.initialize(first, false, false);
      await client.open(caller, 'z.');
      await client.items(caller);
      await client.connection.sendNotification(DidChangeConfigurationNotification.type,
        { settings: { 'z-ls': { zPath: second } } });
      await client.items(caller);
      fs.writeFileSync(path.join(second, 'new.zsh'), 'z.new() { : }\n');
      const before = ticks();
      await expect.poll(ticks).toBeGreaterThan(before);
      expect((await client.items(caller)).map(item => item.label)).toEqual(['z.new', 'z.second']);
      await client.connection.sendNotification(DidChangeConfigurationNotification.type,
        { settings: { 'z-ls': { zPath: '' } } });
      await client.items(caller);
      const empty = ticks();
      await expect.poll(ticks).toBeGreaterThan(empty);
      expect(await client.items(caller)).toEqual([]);
    } finally { await client.close(); }
  }, 15000);

});
