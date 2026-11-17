import path from 'path';
import { fileURLToPath } from 'url';
import type { TextDocument, TextDocuments } from '../vscode_type';

export type DocumentInput = {
  readonly relativePath: string;
  readonly absolutePath: string;
  readonly document: TextDocument;
};

export function relativeProjectPath(projectRoot: string, filename: string): string | null {
  const relative = path.relative(projectRoot, path.resolve(projectRoot, filename));

  return relative &&
    relative !== '..' &&
    !relative.startsWith('..' + path.sep) &&
    !path.isAbsolute(relative) &&
    relative.endsWith('.zsh')
    ? relative
    : null;
}

export function isTrackedDiskPath(relative: string): boolean {
  return !relative
    .split(path.sep)
    .some((segment) => segment === '.git' || segment === 'node_modules');
}

function documentList(
  documents: readonly TextDocument[] | TextDocuments<TextDocument>,
): readonly TextDocument[] {
  if ('all' in documents) {
    return documents.all();
  } else {
    return documents;
  }
}

export function collectOpenProjectDocuments(
  projectRoot: string,
  documents: readonly TextDocument[] | TextDocuments<TextDocument>,
): readonly DocumentInput[] {
  return documentList(documents).flatMap((document) => {
    const absolutePath = filePathFromUri(document.uri);
    const relativePath = absolutePath ? relativeProjectPath(projectRoot, absolutePath) : null;

    if (!absolutePath || !relativePath) {
      return [];
    } else {
      return [
        {
          relativePath,
          absolutePath,
          document,
        },
      ];
    }
  });
}

function filePathFromUri(uri: string): string | null {
  try {
    return fileURLToPath(uri);
  } catch {
    return null;
  }
}
