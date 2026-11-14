import { pathToFileURL } from 'node:url';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import type { FunctionTargets } from '../refreshFunctions/target';
import type { ZshFileHydration } from '../zshHydrator';
import { directivesOf } from '../zshHydrator';
import type { ShellEnvironment } from './environment';
import { emptyShellEnvironment } from './environment';
import { collectFileFacts } from './facts';
import type { FileFacts, Declarations } from './facts';
import { callDiagnostics } from './calls';
import { sameCallContracts } from './contracts';
import type { ResolutionContext } from './calls';
import type { Diagnostics } from './type';

export type FileDiagnostics = {
  readonly file: ZshFileHydration; readonly facts: FileFacts; readonly items: readonly Diagnostics[];
  readonly version: number | null; readonly project: boolean; readonly resultId: string;
};
export type DiagnosticSnapshot = {
  readonly revision: number; readonly targets: FunctionTargets; readonly context: ResolutionContext;
  readonly files: ReadonlyMap<string, FileDiagnostics>;
};

export function createDiagnosticSnapshot(): DiagnosticSnapshot {
  return { revision: 0, targets: new Map(), context: { environment: emptyShellEnvironment(), projectRoot: '',
    aliases: new Set(), globalAliases: new Set(), suffixAliases: new Set(), autoloads: new Set() }, files: new Map() };
}

function sameSet(left: ReadonlySet<string>, right: ReadonlySet<string>): boolean {
  return left.size === right.size && [...left].every(value => right.has(value));
}

function resolutionContext(facts: readonly FileFacts[], environment: ShellEnvironment, projectRoot: string,
  previous: ResolutionContext): ResolutionContext {
  const declarations: Declarations = {
    aliases: new Set(facts.flatMap(file => [...file.declarations.aliases])),
    globalAliases: new Set(facts.flatMap(file => [...file.declarations.globalAliases])),
    suffixAliases: new Set(facts.flatMap(file => [...file.declarations.suffixAliases])),
    autoloads: new Set(facts.flatMap(file => [...file.declarations.autoloads])),
  };
  if (environment === previous.environment && projectRoot === previous.projectRoot &&
    sameSet(declarations.aliases, previous.aliases) && sameSet(declarations.globalAliases, previous.globalAliases) &&
    sameSet(declarations.suffixAliases, previous.suffixAliases) && sameSet(declarations.autoloads, previous.autoloads)) return previous;
  return { ...declarations, environment, projectRoot };
}

function suppressed(file: ZshFileHydration, diagnostics: readonly Diagnostics[]): readonly Diagnostics[] {
  const ignores = new Map<number, ReadonlySet<string>>();
  for (const comment of file.ast.comments) {
    for (const directive of directivesOf(comment)) {
      if (directive.namespace === 'zls' && directive.command === 'ignore') {
        ignores.set(comment.range.start.line, new Set(directive.arguments.map(argument => argument.value)));
      }
    }
  }
  return diagnostics.filter(diagnostic => {
    const codes = ignores.get(diagnostic.range.start.line);
    return !codes || codes.size > 0 && (!diagnostic.code || !codes.has(diagnostic.code));
  });
}

export function refreshDiagnosticSnapshot({ snapshot, environment, previous = createDiagnosticSnapshot() }: {
  readonly snapshot: FunctionSnapshot; readonly environment: ShellEnvironment; readonly previous?: DiagnosticSnapshot;
}): DiagnosticSnapshot {
  const inputs = new Map<string, { file: ZshFileHydration; version: number | null; project: boolean }>();
  for (const file of snapshot.hydrator.files.values()) {
    inputs.set(pathToFileURL(file.sourceFile).href, { file, version: null, project: true });
  }
  for (const [uri, document] of snapshot.documents) {
    inputs.set(uri, { file: document.file, version: document.version, project: inputs.has(uri) });
  }
  const facts = new Map([...inputs].map(([uri, input]) =>
    [uri, previous.files.get(uri)?.file === input.file ? previous.files.get(uri)?.facts ?? collectFileFacts(input.file) :
      collectFileFacts(input.file)]));
  const projectFacts = [...inputs].flatMap(([uri, input]) => input.project ? [facts.get(uri)] : [])
    .filter((file): file is FileFacts => file !== undefined);
  const context = resolutionContext(projectFacts, environment, snapshot.hydrator.projectRoot, previous.context);
  const reusableContracts = sameCallContracts(previous.targets, snapshot.targets);
  const revision = previous.revision + 1;
  const files = new Map<string, FileDiagnostics>();
  for (const [uri, input] of inputs) {
    const cached = previous.files.get(uri);
    const current = facts.get(uri);
    if (!current) continue;
    if (cached && cached.file === input.file && cached.version === input.version && cached.project === input.project &&
      reusableContracts && previous.context === context) {
      files.set(uri, cached);
    } else {
      const local = input.project ? context : resolutionContext([current], environment,
        context.projectRoot, context);
      const effective = input.project ? context : {
        ...context, aliases: new Set([...context.aliases, ...local.aliases]),
        globalAliases: new Set([...context.globalAliases, ...local.globalAliases]),
        suffixAliases: new Set([...context.suffixAliases, ...local.suffixAliases]),
        autoloads: new Set([...context.autoloads, ...local.autoloads]),
      };
      files.set(uri, { ...input, facts: current, resultId: String(revision),
        items: suppressed(input.file, [...current.base, ...callDiagnostics(snapshot, input.file, current.calls, effective)])
          .toSorted((left, right) => left.range.start.line - right.range.start.line ||
            left.range.start.character - right.range.start.character) });
    }
  }
  if (previous.context === context && previous.targets === snapshot.targets && files.size === previous.files.size &&
    [...files].every(([uri, file]) => previous.files.get(uri) === file)) return previous;
  return { revision, files, targets: snapshot.targets, context };
}
