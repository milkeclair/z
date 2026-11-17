import { globSync } from 'glob';
import type { TextDocument, TextDocuments } from '../vscode_type';
import type { HydrationOptions } from './directive';
import {
  hydrateDiskFile,
  hydrateOpenDocument,
  isRegularFile,
  type ZshHydrationEntry,
} from './entry';
import { type HydratedFunction } from './fileHydration';
import {
  collectOpenProjectDocuments,
  isTrackedDiskPath,
  relativeProjectPath,
  type DocumentInput,
} from './inputs';

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

export function createZshHydrator(
  projectRoot: string,
  options: HydrationOptions = {},
): ZshHydrator {
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
  changedPaths,
}: {
  readonly options?: HydrationOptions;
  readonly previous: ZshHydrator;
  readonly projectRoot: string;
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
  // バッファの変更と同時にこれらのディスクパスを照合する。省略すると全走査する。
  // 相対パスはprojectRootを基準に解決する。
  readonly changedPaths?: readonly string[];
}): ZshHydrator {
  if (projectRoot === '') {
    return { ...EmptyZshHydrator, options };
  }
  const compatible =
    previous.projectRoot === projectRoot &&
    JSON.stringify(previous.options) === JSON.stringify(options);
  const inputs = collectOpenProjectDocuments(projectRoot, documents);
  const prior = compatible ? previous : { ...EmptyZshHydrator, options };
  const next =
    changedPaths !== undefined && compatible
      ? updateHydratorFromInputs(prior, inputs, changedPaths)
      : createHydratorFromInputs({ previous: prior, projectRoot, options, documents: inputs });
  const priorPaths = [...previous.files.keys()];
  if (
    compatible &&
    next.diskPaths.size === previous.diskPaths.size &&
    [...next.diskPaths].every((file) => previous.diskPaths.has(file)) &&
    next.files.size === previous.files.size &&
    [...next.files].every(
      ([file, entry], index) => priorPaths[index] === file && previous.files.get(file) === entry,
    )
  ) {
    return previous;
  }
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
  const diskFiles = globSync('**/*.zsh', {
    cwd: projectRoot,
    nodir: true,
    dot: true,
    ignore: ['**/.git/**', '**/node_modules/**'],
  }).sort();
  const diskFileSet = new Set(diskFiles);
  const documentsByPath = new Map(documents.map((input) => [input.relativePath, input]));
  const diskEntries = diskFiles.flatMap((relativePath) => {
    const document = documentsByPath.get(relativePath);
    const entry = document
      ? hydrateOpenDocument({ previous, input: document })
      : hydrateDiskFile({ previous, projectRoot, relativePath });
    return entry ? [entry] : [];
  });
  const documentOnlyEntries = documents
    .filter((document) => !diskFileSet.has(document.relativePath))
    .map((input) => hydrateOpenDocument({ previous, input }));
  const entries = [...diskEntries, ...documentOnlyEntries];

  return {
    projectRoot,
    options,
    files: new Map(entries.map((entry) => [entry.file, entry])),
    diskPaths: diskFileSet,
  };
}

function updateHydratorFromInputs(
  previous: ZshHydrator,
  documents: readonly DocumentInput[],
  changedPaths: readonly string[],
): ZshHydrator {
  const files = new Map(previous.files);
  const diskPaths = new Set(previous.diskPaths);
  const open = new Map(documents.map((input) => [input.relativePath, input]));
  const pending = new Set(
    changedPaths
      .map((filename) => relativeProjectPath(previous.projectRoot, filename))
      .filter((filename): filename is string => filename !== null),
  );
  for (const [filename, entry] of previous.files) {
    if (entry.fingerprint.kind === 'document' && !open.has(filename)) {
      pending.add(filename);
    }
  }
  for (const input of documents) {
    if (!previous.files.has(input.relativePath)) {
      pending.add(input.relativePath);
    }
  }
  for (const filename of pending) {
    const document = open.get(filename);
    if (document) {
      if (isTrackedDiskPath(filename) && isRegularFile(document.absolutePath)) {
        diskPaths.add(filename);
      } else {
        diskPaths.delete(filename);
      }
    } else {
      const entry = isTrackedDiskPath(filename)
        ? hydrateDiskFile({ previous, projectRoot: previous.projectRoot, relativePath: filename })
        : null;
      if (entry) {
        files.set(filename, entry);
        diskPaths.add(filename);
      } else {
        files.delete(filename);
        diskPaths.delete(filename);
      }
    }
  }
  for (const input of documents) {
    files.set(input.relativePath, hydrateOpenDocument({ previous, input }));
  }
  // ディスク上の候補は整列順の優先度を保ち、文書だけに存在する候補は開いた順に並べる。
  const entries = [...diskPaths].sort().flatMap((filename) => {
    const entry = files.get(filename);
    return entry ? [entry] : [];
  });
  for (const input of documents) {
    const entry = files.get(input.relativePath);
    if (entry && !diskPaths.has(input.relativePath)) {
      entries.push(entry);
    }
  }
  return { ...previous, diskPaths, files: new Map(entries.map((entry) => [entry.file, entry])) };
}
