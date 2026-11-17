import { pathToFileURL } from 'node:url';
import type { CodeProgram } from '../embeddedCode';
import { analyzeEmbeddedCode } from '../embeddedCode';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import type { FunctionTargets } from '../refreshFunctions/target';
import type { ZshFileHydration } from '../zshHydrator';
import type { ResolutionContext } from './calls';
import { sameCallContracts } from './contracts';
import { collectIgnoreControls, ignored } from './controls';
import type { ShellEnvironment } from './environment';
import { emptyShellEnvironment } from './environment';
import type { Declarations, FileFacts } from './facts';
import { collectFileFacts } from './facts';
import type { Diagnostics } from './type';

export type FileDiagnostics = {
  readonly file: ZshFileHydration;
  readonly facts: FileFacts;
  readonly items: readonly Diagnostics[];
  readonly codePrograms: readonly CodeProgram[];
  readonly version: number | null;
  readonly project: boolean;
  readonly resultId: string;
};

export type DiagnosticSnapshot = {
  readonly revision: number;
  readonly targets: FunctionTargets;
  readonly context: ResolutionContext;
  readonly files: ReadonlyMap<string, FileDiagnostics>;
};

export function createDiagnosticSnapshot(): DiagnosticSnapshot {
  return {
    revision: 0,
    targets: new Map(),
    context: {
      environment: emptyShellEnvironment(),
      projectRoot: '',
      aliases: new Set(),
      globalAliases: new Set(),
      suffixAliases: new Set(),
      autoloads: new Set(),
      builtins: new Set(),
    },
    files: new Map(),
  };
}

function sameSet(left: ReadonlySet<string>, right: ReadonlySet<string>): boolean {
  return left.size === right.size && [...left].every((value) => right.has(value));
}

function resolutionContext(
  facts: readonly FileFacts[],
  environment: ShellEnvironment,
  projectRoot: string,
  previous: ResolutionContext,
): ResolutionContext {
  const declarations: Declarations = {
    aliases: new Set(facts.flatMap((file) => [...file.declarations.aliases])),
    globalAliases: new Set(facts.flatMap((file) => [...file.declarations.globalAliases])),
    suffixAliases: new Set(facts.flatMap((file) => [...file.declarations.suffixAliases])),
    autoloads: new Set(facts.flatMap((file) => [...file.declarations.autoloads])),
    builtins: new Set(facts.flatMap((file) => [...file.declarations.builtins])),
  };

  if (
    environment === previous.environment &&
    projectRoot === previous.projectRoot &&
    sameSet(declarations.aliases, previous.aliases) &&
    sameSet(declarations.globalAliases, previous.globalAliases) &&
    sameSet(declarations.suffixAliases, previous.suffixAliases) &&
    sameSet(declarations.autoloads, previous.autoloads) &&
    sameSet(declarations.builtins, previous.builtins)
  ) {
    return previous;
  }

  return { ...declarations, environment, projectRoot };
}

function suppressed(
  file: ZshFileHydration,
  diagnostics: readonly Diagnostics[],
): readonly Diagnostics[] {
  const controls = collectIgnoreControls(file);

  return diagnostics.filter(
    (diagnostic) => !ignored(controls, diagnostic.range.start.line, diagnostic.code),
  );
}

type DiagnosticInput = {
  readonly file: ZshFileHydration;
  readonly version: number | null;
  readonly project: boolean;
};

function diagnosticInputs(snapshot: FunctionSnapshot): ReadonlyMap<string, DiagnosticInput> {
  const projectInputs: ReadonlyMap<string, DiagnosticInput> = new Map(
    [...snapshot.hydrator.files.values()].map((file): readonly [string, DiagnosticInput] => [
      pathToFileURL(file.sourceFile).href,
      { file, version: null, project: true },
    ]),
  );
  const inputs: ReadonlyMap<string, DiagnosticInput> = new Map([
    ...projectInputs,
    ...[...snapshot.documents].map(([uri, document]): readonly [string, DiagnosticInput] => [
      uri,
      { file: document.file, version: document.version, project: projectInputs.has(uri) },
    ]),
  ]);

  return inputs;
}

function diagnoseFile(
  snapshot: FunctionSnapshot,
  input: DiagnosticInput,
  facts: FileFacts,
  context: ResolutionContext,
  revision: number,
): FileDiagnostics {
  const local = input.project
    ? context
    : resolutionContext([facts], context.environment, context.projectRoot, context);
  const effective = input.project
    ? context
    : {
        ...context,
        aliases: new Set([...context.aliases, ...local.aliases]),
        globalAliases: new Set([...context.globalAliases, ...local.globalAliases]),
        suffixAliases: new Set([...context.suffixAliases, ...local.suffixAliases]),
        autoloads: new Set([...context.autoloads, ...local.autoloads]),
        builtins: new Set([...context.builtins, ...local.builtins]),
      };
  const embedded = analyzeEmbeddedCode(snapshot, input.file, facts.calls, effective);

  return {
    ...input,
    facts,
    resultId: String(revision),
    codePrograms: embedded.programs,
    items: suppressed(input.file, [...facts.base, ...embedded.diagnostics]).toSorted(
      (left, right) =>
        left.range.start.line - right.range.start.line ||
        left.range.start.character - right.range.start.character,
    ),
  };
}

export function refreshDiagnosticSnapshot({
  snapshot,
  environment,
  previous = createDiagnosticSnapshot(),
}: {
  readonly snapshot: FunctionSnapshot;
  readonly environment: ShellEnvironment;
  readonly previous?: DiagnosticSnapshot;
}): DiagnosticSnapshot {
  const inputs = diagnosticInputs(snapshot);
  const facts = new Map(
    [...inputs].map(([uri, input]) => [
      uri,
      previous.files.get(uri)?.file === input.file
        ? (previous.files.get(uri)?.facts ?? collectFileFacts(input.file))
        : collectFileFacts(input.file),
    ]),
  );
  const projectFacts = [...inputs]
    .flatMap(([uri, input]) => (input.project ? [facts.get(uri)] : []))
    .filter((file): file is FileFacts => file !== undefined);
  const context = resolutionContext(
    projectFacts,
    environment,
    snapshot.hydrator.projectRoot,
    previous.context,
  );
  const reusableContracts = sameCallContracts(previous.targets, snapshot.targets);
  const revision = previous.revision + 1;
  const entries = [...inputs].flatMap(
    ([uri, input]): readonly (readonly [string, FileDiagnostics])[] => {
      const cached = previous.files.get(uri);
      const current = facts.get(uri);

      if (!current) return [];

      if (
        cached &&
        cached.file === input.file &&
        cached.version === input.version &&
        cached.project === input.project &&
        reusableContracts &&
        previous.context === context
      ) {
        return [[uri, cached]];
      }

      return [[uri, diagnoseFile(snapshot, input, current, context, revision)]];
    },
  );
  const files: ReadonlyMap<string, FileDiagnostics> = new Map(entries);

  if (
    previous.context === context &&
    previous.targets === snapshot.targets &&
    files.size === previous.files.size &&
    [...files].every(([uri, file]) => previous.files.get(uri) === file)
  ) {
    return previous;
  }

  return { revision, files, targets: snapshot.targets, context };
}
