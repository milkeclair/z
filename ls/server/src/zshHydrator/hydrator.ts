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
  readonly diskPaths: ReadonlySet<string>;
};

export const EmptyZshHydrator: ZshHydrator = {
  projectRoot: '',
  options: {},
  files: new Map(),
  diskPaths: new Set(),
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
  previous, projectRoot, documents, options = previous.options, changedPaths,
}: {
  readonly options?: HydrationOptions;
  readonly previous: ZshHydrator;
  readonly projectRoot: string;
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
  // Reconcile these disk paths alongside buffer changes; omit for a full scan.
  // Relative paths are resolved against projectRoot.
  readonly changedPaths?: readonly string[];
}): ZshHydrator {
  if (projectRoot === '') return { ...EmptyZshHydrator, options };
  const compatible = previous.projectRoot === projectRoot &&
    JSON.stringify(previous.options) === JSON.stringify(options);
  const inputs = documentInputs(projectRoot, documentList(documents));
  const prior = compatible ? previous : { ...EmptyZshHydrator, options };
  const next = changedPaths !== undefined && compatible
    ? updateHydratorFromInputs(prior, inputs, changedPaths)
    : createHydratorFromInputs({ previous: prior, projectRoot, options, documents: inputs });
  const priorPaths = [...previous.files.keys()];
  if (compatible && next.diskPaths.size === previous.diskPaths.size &&
    [...next.diskPaths].every(file => previous.diskPaths.has(file)) &&
    next.files.size === previous.files.size &&
    [...next.files].every(([file, entry], index) => priorPaths[index] === file &&
      previous.files.get(file) === entry)) return previous;
  return next;
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
    diskPaths: diskFileSet,
  };
}

function projectPath(projectRoot: string, filename: string): string | null {
  const relative = path.relative(projectRoot, path.resolve(projectRoot, filename));
  return relative && relative !== '..' && !relative.startsWith('..' + path.sep) &&
    !path.isAbsolute(relative) && relative.endsWith('.zsh') ? relative : null;
}

function diskPath(relative: string): boolean {
  return !relative.split(path.sep).some(segment => segment === '.git' || segment === 'node_modules');
}

function diskExists(filename: string): boolean {
  try { return fs.statSync(filename).isFile(); }
  catch (error) {
    if (error instanceof Error && 'code' in error &&
      (error.code === 'ENOENT' || error.code === 'ENOTDIR' || error.code === 'EISDIR')) return false;
    throw error;
  }
}

function updateHydratorFromInputs(previous: ZshHydrator, documents: readonly DocumentInput[],
  changedPaths: readonly string[]): ZshHydrator {
  const files = new Map(previous.files);
  const diskPaths = new Set(previous.diskPaths);
  const open = new Map(documents.map(input => [input.relativePath, input]));
  const pending = new Set(changedPaths.map(filename => projectPath(previous.projectRoot, filename))
    .filter((filename): filename is string => filename !== null));
  for (const [filename, entry] of previous.files) {
    if (entry.fingerprint.kind === 'document' && !open.has(filename)) pending.add(filename);
  }
  for (const input of documents) {
    if (!previous.files.has(input.relativePath)) pending.add(input.relativePath);
  }
  for (const filename of pending) {
    const document = open.get(filename);
    if (document) {
      if (diskPath(filename) && diskExists(document.absolutePath)) diskPaths.add(filename);
      else diskPaths.delete(filename);
    } else {
      const entry = diskPath(filename)
        ? diskEntry({ previous, projectRoot: previous.projectRoot, relativePath: filename }) : null;
      if (entry) { files.set(filename, entry); diskPaths.add(filename); }
      else { files.delete(filename); diskPaths.delete(filename); }
    }
  }
  for (const input of documents) files.set(input.relativePath, documentEntry({ previous, input }));
  // Disk candidates retain sorted precedence; document-only candidates follow open order.
  const entries = [...diskPaths].sort().flatMap(filename => {
    const entry = files.get(filename);
    return entry ? [entry] : [];
  });
  for (const input of documents) {
    const entry = files.get(input.relativePath);
    if (entry && !diskPaths.has(input.relativePath)) entries.push(entry);
  }
  return { ...previous, diskPaths, files: new Map(entries.map(entry => [entry.file, entry])) };
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
    const relativePath = absolutePath ? projectPath(projectRoot, absolutePath) : null;

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
