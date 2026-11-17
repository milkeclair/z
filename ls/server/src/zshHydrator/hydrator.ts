import { globSync } from 'glob';
import { OrderedMap, OrderedSet } from 'immutable';
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
  }).toSorted();
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
  const open = new Map(documents.map((input) => [input.relativePath, input]));
  const changed = changedPaths
    .map((filename) => relativeProjectPath(previous.projectRoot, filename))
    .filter((filename): filename is string => filename !== null);
  const closed = [...previous.files].flatMap(([filename, entry]) =>
    entry.fingerprint.kind === 'document' && !open.has(filename) ? [filename] : [],
  );
  const added = documents
    .filter((input) => !previous.files.has(input.relativePath))
    .map((input) => input.relativePath);
  const pending = OrderedSet([...changed, ...closed, ...added]);
  const initial = { files: OrderedMap(previous.files), diskPaths: OrderedSet(previous.diskPaths) };
  const disk = pending.reduce((current, filename) => {
    const document = open.get(filename);
    if (document) {
      return {
        ...current,
        diskPaths:
          isTrackedDiskPath(filename) && isRegularFile(document.absolutePath)
            ? current.diskPaths.add(filename)
            : current.diskPaths.delete(filename),
      };
    }
    const entry = isTrackedDiskPath(filename)
      ? hydrateDiskFile({ previous, projectRoot: previous.projectRoot, relativePath: filename })
      : null;
    return entry
      ? { files: current.files.set(filename, entry), diskPaths: current.diskPaths.add(filename) }
      : { files: current.files.delete(filename), diskPaths: current.diskPaths.delete(filename) };
  }, initial);
  const files = documents.reduce(
    (current, input) => current.set(input.relativePath, hydrateOpenDocument({ previous, input })),
    disk.files,
  );
  const diskEntries = [...disk.diskPaths].toSorted().flatMap((filename) => {
    const entry = files.get(filename);
    return entry ? [entry] : [];
  });
  const openEntries = documents.flatMap((input) => {
    const entry = files.get(input.relativePath);
    return entry && !disk.diskPaths.has(input.relativePath) ? [entry] : [];
  });
  return {
    ...previous,
    diskPaths: new Set(disk.diskPaths),
    files: new Map([...diskEntries, ...openEntries].map((entry) => [entry.file, entry])),
  };
}
