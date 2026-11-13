import os from 'os';
import path from 'path';
import { fileURLToPath } from 'url';
import type { InitializeParams } from '../vscode_type';

export function workspaceProjectRoot(params: InitializeParams): string {
  for (const folder of params.workspaceFolders ?? []) {
    const root = localRoot(folder.uri);
    if (root) return root;
  }
  return localRoot(params.rootUri) || (params.rootPath ? path.resolve(params.rootPath) : '');
}

export function projectRootFromSettings(workspaceRoot: string, fallback: string): string {
  if (workspaceRoot) return workspaceRoot;
  if (!fallback) return '';
  if (fallback === '~') return os.homedir();
  return path.resolve(fallback.startsWith('~/') ? path.join(os.homedir(), fallback.slice(2)) : fallback);
}

function localRoot(uri: string | null | undefined): string {
  if (!uri) return '';
  try {
    return path.resolve(fileURLToPath(uri));
  } catch {
    return '';
  }
}
