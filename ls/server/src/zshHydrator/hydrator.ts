import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { globSync } from 'glob';
import type { TextDocument, TextDocuments } from '../vscode_type';
import { createZshFileHydration, type ZshFileHydration, type HydratedFunction } from './fileHydration';
import type { HydrationOptions } from './directive';

type DiskFingerprint = {
  readonly kind: 'disk';
  readonly mtimeMs: number;
  readonly ctimeMs: number;
  readonly size: number;
};

type DocumentFingerprint = {
  readonly kind: 'document';
  readonly content: string;
  readonly version: number;
  readonly length: number;
};

type Fingerprint = DiskFingerprint | DocumentFingerprint;

type ZshHydrationEntry = ZshFileHydration & {
  readonly fingerprint: Fingerprint;
};

export type ZshHydrator = {
  readonly projectRoot: string;
  readonly options: HydrationOptions;
  readonly files: ReadonlyMap<string, ZshHydrationEntry>;
};

export const EmptyZshHydrator: ZshHydrator = {
  projectRoot: '',
  options: {},
  files: new Map(),
};

type DocumentInput = {
  readonly relativePath: string;
  readonly absolutePath: string;
  readonly document: TextDocument;
};

export function createZshHydrator(projectRoot: string, options: HydrationOptions = {}): ZshHydrator {
  return refreshZshHydrator({
    previous: EmptyZshHydrator,
    projectRoot,
    documents: [],
    options,
  });
}

export function refreshZshHydrator({
  previous,
  projectRoot,
  documents,
  options = previous.options,
}: {
  readonly options?: HydrationOptions;
  readonly previous: ZshHydrator;
  readonly projectRoot: string;
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
}): ZshHydrator {
  if (projectRoot === '') {
    return { ...EmptyZshHydrator, options };
  } else {
    return createHydratorFromInputs({
      previous: previous.projectRoot === projectRoot && JSON.stringify(previous.options) === JSON.stringify(options) ? previous : { ...EmptyZshHydrator, options },
      projectRoot,
      options,
      documents: documentInputs(projectRoot, documentList(documents)),
    });
  }
}

export function functionsFromZshHydrator(hydrator: ZshHydrator): readonly HydratedFunction[] {
  return [...hydrator.files.values()].flatMap((entry) => [...entry.functions]);
}

function createHydratorFromInputs({
  previous,
  projectRoot,
  documents,
  options,
}: {
  readonly options: HydrationOptions;
  readonly previous: ZshHydrator;
  readonly projectRoot: string;
  readonly documents: readonly DocumentInput[];
}): ZshHydrator {
  const diskFiles = globSync('**/*.zsh', { cwd: projectRoot, nodir: true, dot: true, ignore: ['**/.git/**', '**/node_modules/**'] }).sort();
  const diskFileSet = new Set(diskFiles);
  const documentsByPath = new Map(documents.map((input) => [input.relativePath, input]));
  const diskEntries = diskFiles.flatMap((relativePath) => {
    const document = documentsByPath.get(relativePath);
    const entry = document
      ? documentEntry({ previous, input: document })
      : diskEntry({ previous, projectRoot, relativePath });
    return entry ? [entry] : [];
  });
  const documentOnlyEntries = documents
    .filter((document) => !diskFileSet.has(document.relativePath))
    .map((input) => documentEntry({ previous, input }));
  const entries = [...diskEntries, ...documentOnlyEntries];

  return {
    projectRoot,
    options,
    files: new Map(entries.map((entry) => [entry.file, entry])),
  };
}

function diskEntry({
  previous,
  projectRoot,
  relativePath,
}: {
  readonly previous: ZshHydrator;
  readonly projectRoot: string;
  readonly relativePath: string;
}): ZshHydrationEntry | null {
  try {
    const absolutePath = path.join(projectRoot, relativePath);
    const stat = fs.statSync(absolutePath);
    if (!stat.isFile()) return null;
    const fingerprint: DiskFingerprint = {
      kind: 'disk',
      mtimeMs: stat.mtimeMs,
      ctimeMs: stat.ctimeMs,
      size: stat.size,
    };
    const cached = previous.files.get(relativePath);

    if (cached && sameFingerprint(cached.fingerprint, fingerprint)) {
      return cached;
    } else {
      return {
        ...createZshFileHydration({
          sourceFile: absolutePath,
          file: relativePath,
          content: fs.readFileSync(absolutePath, 'utf-8'),
          options: previous.options,
        }),
        fingerprint,
      };
    }
  } catch (error) {
    if (error instanceof Error && 'code' in error &&
      (error.code === 'ENOENT' || error.code === 'ENOTDIR' || error.code === 'EISDIR')) {
      return null;
    }
    throw error;
  }
}

function documentEntry({
  previous,
  input,
}: {
  readonly previous: ZshHydrator;
  readonly input: DocumentInput;
}): ZshHydrationEntry {
  const content = input.document.getText();
  const fingerprint: DocumentFingerprint = {
    kind: 'document',
    content,
    version: input.document.version,
    length: content.length,
  };
  const cached = previous.files.get(input.relativePath);

  if (cached && sameFingerprint(cached.fingerprint, fingerprint)) {
    return cached;
  } else {
    return {
      ...createZshFileHydration({
        sourceFile: input.absolutePath,
        file: input.relativePath,
        content,
        options: previous.options,
      }),
      fingerprint,
    };
  }
}

function sameFingerprint(left: Fingerprint, right: Fingerprint): boolean {
  if (left.kind !== right.kind) {
    return false;
  } else if (left.kind === 'disk' && right.kind === 'disk') {
    return left.mtimeMs === right.mtimeMs && left.ctimeMs === right.ctimeMs && left.size === right.size;
  } else if (left.kind === 'document' && right.kind === 'document') {
    return left.version === right.version && left.length === right.length && left.content === right.content;
  } else {
    return false;
  }
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

function documentInputs(
  projectRoot: string,
  documents: readonly TextDocument[],
): readonly DocumentInput[] {
  return documents.flatMap((document) => {
    const absolutePath = filePathFromUri(document.uri);
    const relativePath = absolutePath ? path.relative(projectRoot, absolutePath) : null;

    if (!absolutePath || !relativePath || (relativePath === '..' || relativePath.startsWith('..' + path.sep)) || path.isAbsolute(relativePath)) {
      return [];
    } else if (!relativePath.endsWith('.zsh')) {
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
