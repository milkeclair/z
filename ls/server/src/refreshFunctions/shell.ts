import path from 'node:path';
import { hydrateDiskFile, type ZshHydrationEntry } from '../zshHydrator/entry';
import type { ZshHydrator } from '../zshHydrator';
import { projectFileFunctions } from './projection';
import type { FunctionTargets } from './target';

export type ShellFunctionIndex = {
  readonly sources: ReadonlyMap<string, string>;
  readonly root: string;
  readonly paths: ReadonlySet<string>;
  readonly files: ReadonlyMap<string, ZshHydrationEntry>;
  readonly targets: FunctionTargets;
};

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
  if (!sources?.size) return undefined;
  if (
    previous?.sources === sources &&
    previous.root === project.projectRoot &&
    changedPaths &&
    !changedPaths.some((file) => previous.paths.has(path.resolve(project.projectRoot, file)))
  ) {
    return previous;
  }

  const projectPaths = new Set([...project.files.values()].map((file) => file.sourceFile));
  const groups = Map.groupBy([...sources], ([, filename]) => filename);
  const entries = [...groups].flatMap(([filename, functions]) => {
    if (!path.isAbsolute(filename) || projectPaths.has(filename)) return [];
    try {
      const file = hydrateDiskFile({
        previous: { ...project, files: previous?.files ?? new Map() },
        projectRoot: project.projectRoot,
        relativePath: filename,
        maxBytes: 2 * 1024 * 1024,
      });
      return file ? [{ filename, file, functions }] : [];
    } catch (error) {
      if (
        error instanceof Error &&
        'code' in error &&
        ['EACCES', 'EPERM'].includes(String(error.code))
      ) {
        return [];
      }
      throw error;
    }
  });
  const files = new Map(entries.map(({ filename, file }) => [filename, file]));
  if (
    previous?.sources === sources &&
    previous.root === project.projectRoot &&
    previous.files.size === files.size &&
    [...files].every(([filename, file]) => previous.files.get(filename) === file)
  )
    return previous;

  const targets: FunctionTargets = new Map(
    entries.flatMap(({ file, functions }) => {
      const definitions = projectFileFunctions(file).targets;
      return functions.flatMap(([name]) => {
        const matches = definitions.get(name);
        return matches?.length === 1 ? [[name, matches] as const] : [];
      });
    }),
  );
  return { sources, root: project.projectRoot, paths: new Set(groups.keys()), files, targets };
}
