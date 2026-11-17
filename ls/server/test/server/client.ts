import { spawn } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, expect } from 'vitest';
import type { CompletionItem, InitializeParams } from 'vscode-languageserver/node';
import {
  CompletionRequest,
  createProtocolConnection,
  DidChangeTextDocumentNotification,
  DidOpenTextDocumentNotification,
  ExitNotification,
  InitializedNotification,
  InitializeRequest,
  RegistrationRequest,
  ShutdownRequest,
} from 'vscode-languageserver/node';
import { createIOState } from '../../src/util/ioState';
import { createTemporaryDirectories } from '../support/tempDirectories';

type LspClientOptions = {
  env?: NodeJS.ProcessEnv;
  rejectWatchRegistration?: boolean;
  preload?: string;
};
type InitializeClientOptions = {
  projectRoot: string;
  supportsRefresh: boolean;
  useWorkspace?: boolean;
};
const temporaryDirectories = createTemporaryDirectories();

export function createProjectDirectory(): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-lsp-stdio-'));
  temporaryDirectories.track(root);
  return root;
}

afterEach(() => {
  temporaryDirectories.cleanup();
});

export async function withRequestTimeout<T>(promise: Promise<T>): Promise<T> {
  const deadline = Promise.withResolvers<never>();
  const timer = setTimeout(() => deadline.reject(new Error('LSP request timed out')), 5000);
  try {
    return await Promise.race([promise, deadline.promise]);
  } finally {
    clearTimeout(timer);
  }
}

export function createLspClient({
  env,
  rejectWatchRegistration = false,
  preload,
}: LspClientOptions = {}) {
  const child = spawn(
    process.execPath,
    [
      ...(preload ? ['--require', preload] : []),
      path.resolve(__dirname, '../../dist/server.js'),
      '--stdio',
    ],
    {
      stdio: 'pipe',
      env,
    },
  );
  const trace = createIOState<{
    readonly stderr: string;
    readonly registrations: readonly string[];
    readonly refreshRequests: readonly string[];
  }>({ stderr: '', registrations: [], refreshRequests: [] });
  child.stderr.on('data', (data: Buffer) => {
    trace.update((previous) => ({ ...previous, stderr: previous.stderr + data.toString() }));
  });
  const exited = new Promise<number | null>((resolve) => {
    child.once('exit', (code) => resolve(code));
  });
  const connection = createProtocolConnection(child.stdout, child.stdin);
  connection.onRequest(RegistrationRequest.type, (params) => {
    trace.update((previous) => ({
      ...previous,
      registrations: [
        ...previous.registrations,
        ...params.registrations.map((registration) => registration.method),
      ],
    }));
    if (rejectWatchRegistration) {
      throw new Error('watch registration rejected by client');
    }
  });
  connection.onRequest('workspace/diagnostic/refresh', () => {
    trace.update((previous) => ({
      ...previous,
      refreshRequests: [...previous.refreshRequests, 'refresh'],
    }));
  });
  connection.listen();
  return {
    connection,
    get registrations() {
      return trace.read().registrations;
    },
    get refreshRequests() {
      return trace.read().refreshRequests;
    },
    async initialize({
      projectRoot: root,
      supportsRefresh: refreshSupport,
      useWorkspace: workspace = true,
    }: InitializeClientOptions) {
      const params: InitializeParams = {
        processId: null,
        rootUri: workspace ? pathToFileURL(root).href : null,
        workspaceFolders: workspace ? [{ name: 'fixture', uri: pathToFileURL(root).href }] : null,
        capabilities: {
          workspace: {
            didChangeWatchedFiles: { dynamicRegistration: refreshSupport },
            diagnostics: { refreshSupport },
          },
        },
        initializationOptions: { zPath: workspace ? path.join(root, 'unused-legacy-root') : root },
      };
      const result = await withRequestTimeout(
        connection.sendRequest(InitializeRequest.type, params),
      );
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
        textDocument: { uri, version },
        contentChanges: [{ text: content }],
      });
    },
    async items(uri: string, character = 2): Promise<CompletionItem[]> {
      const result = await withRequestTimeout(
        connection.sendRequest(CompletionRequest.type, {
          textDocument: { uri },
          position: { line: 0, character },
        }),
      );
      return Array.isArray(result) ? result : (result?.items ?? []);
    },
    async close() {
      try {
        if (child.exitCode === null) {
          await withRequestTimeout(connection.sendRequest(ShutdownRequest.type));
          await connection.sendNotification(ExitNotification.type);
        }
        const code = await withRequestTimeout(exited);
        const stderr = trace.read().stderr;
        expect(code, stderr).toBe(0);
        expect(stderr).toBe('');
      } finally {
        connection.dispose();
        if (child.exitCode === null) {
          child.kill('SIGKILL');
        }
        await withRequestTimeout(exited);
      }
    },
  };
}

export function createObservedLspClient(root: string) {
  const filename = path.join(root, 'parsed.jsonl');
  const preload = path.join(root, 'observe.cjs');
  fs.writeFileSync(filename, '');
  fs.writeFileSync(
    preload,
    [
      "const fs = require('node:fs');",
      'const hydration = require(' +
        JSON.stringify(path.resolve(__dirname, '../../dist/zshHydrator/fileHydration.js')) +
        ');',
      'const original = hydration.createZshFileHydration;',
      'hydration.createZshFileHydration = input => {',
      '  const result = original(input);',
      '  fs.appendFileSync(' +
        JSON.stringify(filename) +
        ', JSON.stringify({ sourceFile: input.sourceFile, content: input.content }) + "\\n");',
      '  return result;',
      '};',
    ].join('\n'),
  );
  return {
    client: createLspClient({ rejectWatchRegistration: false, preload: preload }),
    parsed: () => fs.readFileSync(filename, 'utf8').split('\n').filter(Boolean),
  };
}

export function createPeriodicLspClient(root: string) {
  const filename = path.join(root, 'ticks.log');
  const preload = path.join(root, 'periodic-clock.cjs');
  fs.writeFileSync(filename, '');
  fs.writeFileSync(
    preload,
    [
      "const fs = require('node:fs');",
      'const original = global.setInterval;',
      'global.setInterval = (callback, delay, ...args) => {',
      '  if (delay !== 60000) return original(callback, delay, ...args);',
      '  return original(() => {',
      '    try { callback(...args); }',
      '    finally { fs.appendFileSync(' + JSON.stringify(filename) + ', "tick\\n"); }',
      '  }, 100);',
      '};',
    ].join('\n'),
  );
  return {
    client: createLspClient({ rejectWatchRegistration: false, preload: preload }),
    ticks: () => fs.readFileSync(filename, 'utf8').length,
  };
}
