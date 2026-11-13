import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { zInitialize } from '../../src/connection/initialize';
import type { InitializeParams } from '../../src/vscode_type';

const roots: string[] = [];
function fixture(): string {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-initialize-'));
  roots.push(root);
  return root;
}
afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});
function initialize(params: Partial<InitializeParams>) {
  return zInitialize({ processId: null, rootUri: null, capabilities: {}, ...params });
}

describe('zInitialize@hydration', () => {
  test('workspaceフォルダをzPathより優先して一般名の関数を取得する', () => {
    const root = fixture();
    const legacy = fixture();
    fs.writeFileSync(path.join(root, 'sample.zsh'), 'greet() { : }\n');
    fs.writeFileSync(path.join(legacy, 'legacy.zsh'), 'z.legacy() { : }\n');
    const result = initialize({
      workspaceFolders: [{ uri: pathToFileURL(root).href, name: 'workspace' }],
      initializationOptions: { zPath: legacy },
    });
    expect(result.projectRoot).toBe(root);
    expect(result.functions.map(fn => fn.name)).toEqual(['greet']);
    expect(result.snapshot.hydrator.projectRoot).toBe(root);
    expect(result.serverCapabilities.capabilities.textDocumentSync).toMatchObject({ save: true });
  });

  test('rootUriと旧rootPathをローカルルートとして扱う', () => {
    const root = fixture();
    expect(initialize({ rootUri: pathToFileURL(root).href }).projectRoot).toBe(root);
    expect(initialize({ rootPath: root }).projectRoot).toBe(root);
    expect(initialize({ rootUri: 'untitled:root', rootPath: root }).projectRoot).toBe(root);
  });

  test('workspaceのない既存クライアントは設定したzPathへフォールバックする', () => {
    const root = fixture();
    fs.writeFileSync(path.join(root, 'sample.zsh'), 'z.legacy() { : }\n');
    const result = initialize({ initializationOptions: { zPath: root } });
    expect(result.workspaceRoot).toBe('');
    expect(result.projectRoot).toBe(root);
    expect(result.functions[0].name).toBe('z.legacy');
  });
});
