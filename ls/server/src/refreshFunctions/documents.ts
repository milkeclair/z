import path from 'path';
import { fileURLToPath } from 'url';
import { createZshFileHydration } from '../zshHydrator';
import type { ZshFileHydration, ZshHydrator } from '../zshHydrator';
import type { TextDocument } from '../vscode_type';

export type DocumentSnapshot = {
  readonly version: number; readonly content: string; readonly file: ZshFileHydration;
};
export type DocumentSnapshots = ReadonlyMap<string, DocumentSnapshot>;

export function documentSnapshots(
  documents: readonly TextDocument[], hydrator: ZshHydrator, previous: DocumentSnapshots,
): DocumentSnapshots {
  const next = new Map<string, DocumentSnapshot>();
  for (const document of documents) {
    let sourceFile: string;
    try { sourceFile = fileURLToPath(document.uri); } catch { continue; }
    if (!sourceFile.endsWith('.zsh')) continue;
    const content = document.getText();
    const cached = previous.get(document.uri);
    const relative = hydrator.projectRoot ? path.relative(hydrator.projectRoot, sourceFile) : '';
    const projectFile = hydrator.files.get(relative);
    if (cached && cached.version === document.version && cached.content === content &&
      (!projectFile || projectFile === cached.file)) {
      next.set(document.uri, cached);
      continue;
    }
    next.set(document.uri, { version: document.version, content,
      file: projectFile ?? createZshFileHydration({ sourceFile, file: sourceFile, content, options: hydrator.options }) });
  }
  if (next.size === previous.size && [...next].every(([uri, value]) => previous.get(uri) === value)) return previous;
  return next;
}
