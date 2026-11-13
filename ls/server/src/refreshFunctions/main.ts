import type { TextDocuments, TextDocument } from '../vscode_type';
import type { Func } from '../getFunctions/type';
import { EmptyZshHydrator, refreshZshHydrator } from '../zshHydrator';
import type { ZshHydrator } from '../zshHydrator';
import { projectFunctions } from './projection';
import { documentSnapshots } from './documents';
import type { DocumentSnapshots } from './documents';
import type { FunctionTargets } from './target';

export type FunctionSnapshot = {
  readonly hydrator: ZshHydrator;
  readonly functions: Func[];
  readonly targets: FunctionTargets;
  readonly documents: DocumentSnapshots;
};

export function createFunctionSnapshot(): FunctionSnapshot {
  return { hydrator: EmptyZshHydrator, functions: [], targets: new Map(), documents: new Map() };
}

type RefreshInput = {
  readonly projectRoot: string;
  readonly changedPaths?: readonly string[];
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
};

export function refreshFunctionSnapshot({
  projectRoot, documents, changedPaths, previous = createFunctionSnapshot(),
}: RefreshInput & { readonly previous?: FunctionSnapshot }): FunctionSnapshot {
  const inputs = 'all' in documents ? documents.all() : documents;
  const hydrator = refreshZshHydrator({ previous: previous.hydrator, projectRoot, documents: inputs, changedPaths });
  const open = documentSnapshots(inputs, hydrator, previous.documents);
  if (previous.hydrator === hydrator && open === previous.documents) return previous;
  const projection = sameFunctionFiles(previous.hydrator, hydrator)
    ? { functions: previous.functions, targets: previous.targets } : projectFunctions(hydrator);
  return { hydrator, functions: projection.functions, targets: projection.targets, documents: open };
}

export function refreshFunctions(input: RefreshInput): Func[] {
  return refreshFunctionSnapshot(input).functions;
}

function sameFunctionFiles(left: ZshHydrator, right: ZshHydrator): boolean {
  const before = [...left.files.values()].filter(entry => entry.functions.length > 0);
  const after = [...right.files.values()].filter(entry => entry.functions.length > 0);
  return before.length === after.length && before.every((entry, index) => after[index] === entry);
}
