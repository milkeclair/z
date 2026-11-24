import type { Func } from '../getFunctions/type';
import type { TextDocument, TextDocuments } from '../vscode_type';
import type { ZshHydrator } from '../zshHydrator';
import { EmptyZshHydrator, refreshZshHydrator } from '../zshHydrator';
import type { DocumentSnapshots } from './documents';
import { documentSnapshots } from './documents';
import type { FileFunctionProjections } from './projection';
import { projectFunctions } from './projection';
import type { FunctionTargets } from './target';
import { refreshShellFunctions, type ShellFunctionIndex } from './shell';

export type FunctionSnapshot = {
  readonly hydrator: ZshHydrator;
  readonly functions: readonly Func[];
  readonly targets: FunctionTargets;
  readonly documents: DocumentSnapshots;
  readonly shellFunctions?: ShellFunctionIndex;
  readonly fileProjections: FileFunctionProjections;
};

export function createFunctionSnapshot(): FunctionSnapshot {
  return {
    hydrator: EmptyZshHydrator,
    functions: [],
    targets: new Map(),
    documents: new Map(),
    fileProjections: new Map(),
  };
}

type RefreshInput = {
  readonly projectRoot: string;
  readonly changedPaths?: readonly string[];
  readonly functionSources?: ReadonlyMap<string, string>;
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
};

export function refreshFunctionSnapshot({
  projectRoot,
  documents,
  changedPaths,
  functionSources,
  previous = createFunctionSnapshot(),
}: RefreshInput & {
  readonly previous?: FunctionSnapshot;
}): FunctionSnapshot {
  const inputs = 'all' in documents ? documents.all() : documents;
  const hydrator = refreshZshHydrator({
    previous: previous.hydrator,
    projectRoot,
    documents: inputs,
    changedPaths,
  });
  const open = documentSnapshots(inputs, hydrator, previous.documents);

  const shellFunctions = refreshShellFunctions({
    sources: functionSources,
    project: hydrator,
    previous: previous.shellFunctions,
    changedPaths,
  });

  if (
    previous.hydrator === hydrator &&
    open === previous.documents &&
    previous.shellFunctions === shellFunctions
  ) {
    return previous;
  }

  const projection = sameFunctionFiles(previous.hydrator, hydrator)
    ? {
        functions: previous.functions,
        targets: previous.targets,
        fileProjections: previous.fileProjections,
      }
    : projectFunctions(hydrator, previous.fileProjections);

  return {
    hydrator,
    functions: projection.functions,
    targets: projection.targets,
    documents: open,
    ...(shellFunctions ? { shellFunctions } : {}),
    fileProjections: projection.fileProjections,
  };
}

export function refreshFunctions(input: RefreshInput): readonly Func[] {
  return refreshFunctionSnapshot(input).functions;
}

function sameFunctionFiles(left: ZshHydrator, right: ZshHydrator): boolean {
  const before = [...left.files.values()].filter((entry) => entry.functions.length > 0);
  const after = [...right.files.values()].filter((entry) => entry.functions.length > 0);

  return before.length === after.length && before.every((entry, index) => after[index] === entry);
}
