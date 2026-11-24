import path from 'node:path';
import { hydrateDiskFile, type ZshHydrationEntry } from '../zshHydrator/entry';
import type { ZshHydrator } from '../zshHydrator';
import { projectFileFunctions } from './projection';
import type { FunctionTarget, FunctionTargets } from './target';

export type ShellFunctionIndex = {
  readonly sources: ReadonlyMap<string, string>;
  readonly root: string;
  readonly paths: ReadonlySet<string>;
  readonly files: ReadonlyMap<string, ZshHydrationEntry>;
  readonly targets: FunctionTargets;
};

const MAX_DEFINITION_BYTES = 2 * 1024 * 1024;

/** シェルが報告した定義に読み取り権限がなければ、ほかの定義の索引化を続ける。 */
function readShellDefinition(previous: ZshHydrator, filename: string): ZshHydrationEntry | null {
  try {
    return hydrateDiskFile({
      previous,
      projectRoot: previous.projectRoot,
      relativePath: filename,
      maxBytes: MAX_DEFINITION_BYTES,
    });
  } catch (error) {
    if (
      error instanceof Error &&
      'code' in error &&
      (error.code === 'EACCES' || error.code === 'EPERM')
    ) {
      return null;
    }

    throw error;
  }
}

/** 起動済み関数の名前と定義元を対応付け、外部の定義を索引に足す。 */
export function refreshShellFunctions({
  sources,
  project,
  previous,
  changedPaths,
}: {
  readonly sources?: ReadonlyMap<string, string>;
  readonly project: ZshHydrator;
  readonly previous?: ShellFunctionIndex;
  readonly changedPaths?: readonly string[];
}): ShellFunctionIndex | undefined {
  if (!sources?.size) {
    return undefined;
  }

  if (
    previous?.sources === sources &&
    previous.root === project.projectRoot &&
    changedPaths &&
    !changedPaths.some((file) => previous.paths.has(path.resolve(project.projectRoot, file)))
  ) {
    return previous;
  }

  const projectPaths = new Set([...project.files.values()].map((file) => file.sourceFile));
  const sourcesByFile = Map.groupBy(sources, ([, filename]) => filename);
  const cached = { ...project, files: previous?.files ?? new Map<string, ZshHydrationEntry>() };
  const files = new Map<string, ZshHydrationEntry>();

  for (const filename of sourcesByFile.keys()) {
    if (!path.isAbsolute(filename) || projectPaths.has(filename)) continue;
    const file = readShellDefinition(cached, filename);
    if (file) files.set(filename, file);
  }

  if (
    previous?.sources === sources &&
    previous.root === project.projectRoot &&
    previous.files.size === files.size &&
    [...files].every(([filename, file]) => previous.files.get(filename) === file)
  ) {
    return previous;
  }

  const targets = new Map<string, readonly FunctionTarget[]>();
  for (const [filename, file] of files) {
    const definitions = projectFileFunctions(file).targets;
    for (const [name] of sourcesByFile.get(filename) ?? []) {
      const matches = definitions.get(name);
      if (matches?.length === 1) targets.set(name, matches);
    }
  }

  return {
    sources,
    root: project.projectRoot,
    paths: new Set(sourcesByFile.keys()),
    files,
    targets,
  };
}
