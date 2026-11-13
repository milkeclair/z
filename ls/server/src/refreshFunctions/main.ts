import type { TextDocuments, TextDocument } from '../vscode_type';
import type { Func } from '../getFunctions/type';
import { EmptyZshHydrator, refreshZshHydrator } from '../zshHydrator';
import type { ZshHydrator } from '../zshHydrator';
import { functionsFromHydrator } from './projection';

export type FunctionSnapshot = {
  readonly hydrator: ZshHydrator;
  readonly functions: Func[];
};

export function createFunctionSnapshot(): FunctionSnapshot {
  return { hydrator: EmptyZshHydrator, functions: [] };
}

type RefreshInput = {
  readonly projectRoot: string;
  readonly documents: readonly TextDocument[] | TextDocuments<TextDocument>;
};

export function refreshFunctionSnapshot({
  projectRoot, documents, previous = createFunctionSnapshot(),
}: RefreshInput & { readonly previous?: FunctionSnapshot }): FunctionSnapshot {
  const hydrator = refreshZshHydrator({ previous: previous.hydrator, projectRoot, documents });
  if (sameFiles(previous.hydrator, hydrator)) return previous;
  return { hydrator, functions: sameFunctionFiles(previous.hydrator, hydrator)
    ? previous.functions : functionsFromHydrator(hydrator) };
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
