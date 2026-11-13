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
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
};

export function refreshFunctionSnapshot({
  projectRoot, documents, previous = createFunctionSnapshot(),
}: RefreshInput & { readonly previous?: FunctionSnapshot }): FunctionSnapshot {
  const inputs = 'all' in documents ? documents.all() : documents;
  const hydrator = refreshZshHydrator({ previous: previous.hydrator, projectRoot, documents: inputs });
  const open = documentSnapshots(inputs, hydrator, previous.documents);
  if (sameFiles(previous.hydrator, hydrator) && open === previous.documents) return previous;
  const projection = sameFunctionFiles(previous.hydrator, hydrator)
    ? { functions: previous.functions, targets: previous.targets } : projectFunctions(hydrator);
  return { hydrator, functions: projection.functions, targets: projection.targets, documents: open };
}

export function refreshFunctions(input: RefreshInput): Func[] {
  return refreshFunctionSnapshot(input).functions;
}

function sameFiles(left: ZshHydrator, right: ZshHydrator): boolean {
  return left.projectRoot === right.projectRoot && left.options === right.options &&
    left.files.size === right.files.size &&
    [...left.files].every(([file, entry]) => right.files.get(file) === entry);
}

function sameFunctionFiles(left: ZshHydrator, right: ZshHydrator): boolean {
  for (const [file, entry] of left.files) {
    if (entry.functions.length && right.files.get(file) !== entry) return false;
  }
  for (const [file, entry] of right.files) {
    if (entry.functions.length && left.files.get(file) !== entry) return false;
  }
  return true;
}
