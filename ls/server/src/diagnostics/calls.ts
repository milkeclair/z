import {
  addValue,
  appendItems,
  collectArray,
  makeMap,
  makeSet,
  mapValues,
  setEntry,
} from '../util/collections';
import { resolveFunction } from '../connection/ast/context';
import { functionCommand, protocolRange } from '../connection/ast/cursor';
import { namedKey } from '../connection/ast/word';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { literalWord } from '../refreshFunctions/word';
import { DiagnosticSeverity } from '../vscode_type';
import type { ZshFileHydration } from '../zshHydrator';
import { documentationOf } from '../zshHydrator';
import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { SourceRange } from '../zshParser/lexer';
import { classMemberReference, resolveInstanceCommand, type ClassCommandTarget } from './classes';
import { isAliasReference, isKnownShellCommand, type ResolutionContext } from './commandResolution';
import type { IgnoreControls } from './controls';
import { ignored } from './controls';
import { simpleParameter } from './facts';
import { resolveSelfCommand } from './self';
import type { Diagnostics } from './type';

export type { ResolutionContext } from './commandResolution';

export function uncertainWord(word: WordNode, context: ResolutionContext): boolean {
  const environment = context.environment;
  const literal = literalWord(word);

  if (literal !== null) {
    if (
      !word.quoted &&
      (context.globalAliases.has(literal) ||
        (environment.kind === 'available' && environment.globalAliases.has(literal)))
    ) {
      return true;
    }

    return !word.quoted && [...word.raw].some((char) => '*?[{~('.includes(char));
  }

  if (word.quoteKind !== 'double') {
    return true;
  }

  return word.parts.some(
    (part) =>
      part.kind === 'parameterExpansion' &&
      (simpleParameter(part.raw) === null || simpleParameter(part.raw) === '@'),
  );
}

function argumentDiagnostics(
  command: SimpleCommandNode,
  definition: FunctionDefinitionNode,
  context: ResolutionContext,
  mapRange: (range: SourceRange) => SourceRange,
): readonly Diagnostics[] {
  const parameters = documentationOf(definition)?.parameters ?? [];

  if (!parameters.length || command.arguments.some((word) => uncertainWord(word, context))) {
    return [];
  }

  const named = new Set(
    parameters
      .filter((parameter) => parameter.kind === 'namedParameterDoc')
      .map((parameter) => parameter.name),
  );
  const supplied = command.arguments.reduce(
    (current, word) => {
      const key = namedKey(word);

      return key && named.has(key)
        ? { ...current, present: addValue(current.present, key) }
        : { ...current, positional: current.positional + 1 };
    },
    { present: makeSet<string>(), positional: 0 },
  );
  const { present, positional } = supplied;
  const range = protocolRange(mapRange(command.commandName?.range ?? command.range));
  const missing = parameters.filter(
    (parameter) =>
      parameter.kind === 'positionalParameterDoc' &&
      !parameter.optional &&
      parameter.position > positional,
  );
  const positionalDiagnostics: readonly Diagnostics[] = missing.length
    ? [
        {
          severity: DiagnosticSeverity.Error,
          code: 'missing-positional-argument',
          range,
          source: 'z-ls',
          message:
            'Missing required argument(s): ' +
            missing
              .map((parameter) =>
                parameter.kind === 'positionalParameterDoc' ? '$' + parameter.position : '',
              )
              .join(', '),
        },
      ]
    : [];
  const namedDiagnostics = parameters.flatMap((parameter): readonly Diagnostics[] =>
    parameter.kind === 'namedParameterDoc' && !parameter.optional && !present.has(parameter.name)
      ? [
          {
            severity: DiagnosticSeverity.Error,
            code: 'missing-named-argument',
            range,
            source: 'z-ls',
            message: 'Missing required named argument: ' + parameter.name,
          },
        ]
      : [],
  );

  return [...positionalDiagnostics, ...namedDiagnostics];
}

export type CallScope = {
  readonly file: ZshFileHydration;
  readonly offset: number;
};

export type CallAnalysisOptions = {
  readonly scopes?: readonly CallScope[];
  readonly mapRange?: (range: SourceRange) => SourceRange;
  readonly ignores?: IgnoreControls;
};

export type CallAnalysis = {
  readonly diagnostics: readonly Diagnostics[];
  readonly targets: ReadonlyMap<SimpleCommandNode, FunctionDefinitionNode>;
  readonly classTargets: ReadonlyMap<SimpleCommandNode, readonly ClassCommandTarget[]>;
};

/** 埋め込みコードやworkspace外の定義はローカルに保ち、workspaceの参照先には追加しない。 */
function localDefinitions(
  snapshot: FunctionSnapshot,
  file: ZshFileHydration,
): ReadonlyMap<string, readonly FunctionDefinitionNode[]> {
  if (snapshot.hydrator.files.get(file.file) === file) {
    return new Map();
  }

  const grouped = [...makeSet(file.functions.map((entry) => entry.definition))].reduce(
    (groups, definition) =>
      definition.names.reduce((previous, word) => {
        const name = literalWord(word);

        return name
          ? setEntry(
              previous,
              name,
              appendItems(previous.get(name) ?? collectArray<FunctionDefinitionNode>(), definition),
            )
          : previous;
      }, groups),
    makeMap<string, ReadonlyArray<FunctionDefinitionNode>>(),
  );

  return new Map(mapValues(grouped, (definitions) => definitions));
}

/** 既存の前方参照の動作を保ちながら、直前にある最も近い定義を優先する。 */
function localDefinition(
  definitions: ReadonlyMap<string, readonly FunctionDefinitionNode[]>,
  name: string,
  offset: number,
) {
  const candidates = definitions.get(name) ?? [];

  return (
    candidates.findLast((definition) => definition.range.start.offset <= offset) ?? candidates[0]
  );
}

/** 解決済みの関数参照をコード引数の解析でも再利用し、報告する位置だけを変換する。 */
export function analyzeCalls(
  snapshot: FunctionSnapshot,
  file: ZshFileHydration,
  commands: readonly SimpleCommandNode[],
  context: ResolutionContext,
  options: CallAnalysisOptions = {},
): CallAnalysis {
  const local = localDefinitions(snapshot, file);
  const scopes = (options.scopes ?? []).map((scope) => ({
    ...scope,
    definitions: localDefinitions(snapshot, scope.file),
  }));
  const origin = scopes.at(-1);
  const mapRange = options.mapRange ?? ((range) => range);
  const incomplete = file.lexerDiagnostics.length > 0 || file.parserDiagnostics.length > 0;
  const initial = {
    diagnostics: collectArray<Diagnostics>(),
    targets: makeMap<SimpleCommandNode, FunctionDefinitionNode>(),
    classTargets: makeMap<SimpleCommandNode, readonly ClassCommandTarget[]>(),
  };
  const result = commands.reduce((previous, command) => {
    const word = command.commandName?.word;
    if (!word) return previous;

    const reference = functionCommand(command) ? classMemberReference(word) : null;
    const member = reference
      ? (resolveInstanceCommand(file, word, reference, context.classFiles) ??
        (reference.binding === 'self'
          ? resolveSelfCommand(file, word, reference.member, scopes)
          : null))
      : null;
    if (member) {
      if (member.target) {
        return {
          ...previous,
          classTargets: setEntry(previous.classTargets, command, [member.target]),
        };
      }

      return options.ignores && ignored(options.ignores, word.range.start.line, 'undefined-command')
        ? previous
        : {
            ...previous,
            diagnostics: appendItems(previous.diagnostics, {
              severity: DiagnosticSeverity.Error,
              code: 'undefined-command',
              range: protocolRange(mapRange(word.range)),
              source: 'z-ls',
              message: member.name + ' is not defined in class ' + member.definition.name + '.',
            }),
          };
    }

    const name = literalWord(word);

    if (!name || (!word.quoted && word.raw.startsWith('=')) || uncertainWord(word, context)) {
      return previous;
    }

    const inspect = command.precommandModifiers.some(
      (modifier) =>
        modifier.type === 'command' &&
        modifier.options.some((option) => option.name.includes('v') || option.name.includes('V')),
    );

    if (inspect || isAliasReference(name, word, context)) {
      return previous;
    }

    const inherited = scopes
      .map((scope) => localDefinition(scope.definitions, name, scope.offset))
      .find((target) => target !== undefined);
    const target = functionCommand(command)
      ? (localDefinition(local, name, word.range.start.offset) ??
        inherited ??
        resolveFunction(snapshot, name, {
          file: origin?.file ?? file,
          offset: origin?.offset ?? word.range.start.offset,
        })?.definition)
      : null;

    if (target) {
      const diagnostics = incomplete
        ? previous.diagnostics
        : previous.diagnostics.concat(
            argumentDiagnostics(command, target, context, mapRange).filter(
              (diagnostic) =>
                !options.ignores ||
                !ignored(options.ignores, word.range.start.line, diagnostic.code),
            ),
          );

      return {
        ...previous,
        diagnostics,
        targets: setEntry(previous.targets, command, target),
      };
    }

    if (context.autoloads.has(name) && functionCommand(command)) {
      return previous;
    }

    const unknown =
      isKnownShellCommand(name, command, context) === false &&
      (!options.ignores || !ignored(options.ignores, word.range.start.line, 'undefined-command'));

    return unknown
      ? {
          ...previous,
          diagnostics: appendItems(previous.diagnostics, {
            severity: DiagnosticSeverity.Error,
            code: 'undefined-command',
            range: protocolRange(mapRange(word.range)),
            source: 'z-ls',
            message: name + ' is not defined in the project or shell environment.',
          }),
        }
      : previous;
  }, initial);

  return {
    diagnostics: result.diagnostics,
    targets: new Map(result.targets),
    classTargets: new Map(result.classTargets),
  };
}

/** 関数の参照先を必要としない呼び出し元向けに、既存の診断のみを返すAPIを保つ。 */
export function callDiagnostics(
  snapshot: FunctionSnapshot,
  file: ZshFileHydration,
  commands: readonly SimpleCommandNode[],
  context: ResolutionContext,
): readonly Diagnostics[] {
  return analyzeCalls(snapshot, file, commands, context).diagnostics;
}
