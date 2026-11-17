import path from 'node:path';
import { fileURLToPath } from 'node:url';
import type { TextDocument } from '../vscode_type';
import type { ZshFileHydration, ZshHydrator } from '../zshHydrator';
import { createZshFileHydration } from '../zshHydrator';
import { projectFileFunctions } from './projection';
import type { FunctionTargets } from './target';

export type DocumentSnapshot = {
  readonly version: number;
  readonly content: string;
  readonly file: ZshFileHydration;
  readonly targets?: FunctionTargets;
};

export type DocumentSnapshots = ReadonlyMap<string, DocumentSnapshot>;

function sourcePath(uri: string): string | null {
  try {
    return fileURLToPath(uri);
  } catch {
    return null;
  }
}

function snapshotForDocument(
  document: TextDocument,
  hydrator: ZshHydrator,
  previous: DocumentSnapshots,
): readonly (readonly [string, DocumentSnapshot])[] {
  const sourceFile = sourcePath(document.uri);

  if (!sourceFile?.endsWith('.zsh')) {
    return [];
  }

  const content = document.getText();
  const cached = previous.get(document.uri);
  const relative = hydrator.projectRoot ? path.relative(hydrator.projectRoot, sourceFile) : '';
  const projectFile = hydrator.files.get(relative);
  const local = projectFile === undefined;

  if (
    cached &&
    cached.version === document.version &&
    cached.content === content &&
    (!projectFile || projectFile === cached.file) &&
    (cached.targets !== undefined) === local
  ) {
    return [[document.uri, cached]];
  }

  const file =
    projectFile ??
    createZshFileHydration({ sourceFile, file: sourceFile, content, options: hydrator.options });

  return [
    [
      document.uri,
      {
        version: document.version,
        content,
        file,
        ...(local ? { targets: projectFileFunctions(file).targets } : {}),
      },
    ],
  ];
}

export function documentSnapshots(
  documents: readonly TextDocument[],
  hydrator: ZshHydrator,
  previous: DocumentSnapshots,
): DocumentSnapshots {
  const next: DocumentSnapshots = new Map(
    documents.flatMap((document) => snapshotForDocument(document, hydrator, previous)),
  );

  return next.size === previous.size &&
    [...next].every(([uri, value]) => previous.get(uri) === value)
    ? previous
    : next;
}
