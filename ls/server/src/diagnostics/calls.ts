import fs from 'node:fs';
import path from 'node:path';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { ZshFileHydration } from '../zshHydrator';
import { documentationOf } from '../zshHydrator';
import { literalWord } from '../refreshFunctions/word';
import { namedKey } from '../connection/ast/word';
import { protocolRange, functionCommand } from '../connection/ast/cursor';
import { resolveFunction } from '../connection/ast/context';
import { DiagnosticSeverity } from '../vscode_type';
import type { Diagnostics } from './type';
import type { SourceRange } from '../zshParser/lexer';
import type { IgnoreControls } from './controls';
import { ignored } from './controls';
import type { ShellEnvironment } from './environment';
import type { Declarations } from './facts';
import { simpleParameter } from './facts';
import type { ClassFileHydration } from '../zshHydrator';
import type { ClassCommandTargets, ClassCommandTarget } from './classes';

export type ResolutionContext = Declarations & {
  readonly environment: ShellEnvironment; readonly projectRoot: string;
  readonly classCommands: ClassCommandTargets;
  readonly classFiles: readonly ClassFileHydration[];
};

function alias(name: string, word: WordNode, context: ResolutionContext): boolean {
  if (word.quoted || word.raw !== name) return false;
  const environment = context.environment;
  const suffix = name.slice(name.lastIndexOf('.') + 1);
  return context.aliases.has(name) || context.globalAliases.has(name) ||
    name.includes('.') && context.suffixAliases.has(suffix) ||
    environment.kind === 'available' && (environment.aliases.has(name) || environment.globalAliases.has(name) ||
      name.includes('.') && environment.suffixAliases.has(suffix));
}

function executable(name: string, context: ResolutionContext): boolean | null {
  if (!name.includes('/')) return null;
  const filename = path.isAbsolute(name) ? name : context.projectRoot ? path.resolve(context.projectRoot, name) : null;
  if (!filename) return null;
  try {
    if (!fs.statSync(filename).isFile()) return path.isAbsolute(name) ? false : null;
    fs.accessSync(filename, fs.constants.X_OK);
    return true;
  } catch { return path.isAbsolute(name) ? false : null; }
}

function shellKnown(name: string, command: SimpleCommandNode, context: ResolutionContext): boolean | null {
  const environment = context.environment;
  if (environment.kind !== 'available') return null;
  const builtin = command.precommandModifiers.some(modifier => modifier.type === 'builtin');
  const knownBuiltin = environment.builtins.has(name) || context.builtins.has(name);
  if (builtin) return knownBuiltin;
  const commandOnly = command.precommandModifiers.some(modifier => modifier.type === 'command');
  if (command.precommandModifiers.some(modifier => modifier.type === 'command' &&
    modifier.options.some(option => option.name.includes('p')))) return null;
  if (!commandOnly && environment.functions.has(name)) return true;
  if (name.includes('/')) return executable(name, context);
  return environment.commands.has(name) || (!commandOnly || environment.commandBuiltins) && knownBuiltin ||
    !commandOnly && (environment.functions.has(name) || context.autoloads.has(name));
}

export function uncertainWord(word: WordNode, context: ResolutionContext): boolean {
  const environment = context.environment;
  const literal = literalWord(word);
  if (literal !== null) {
    if (!word.quoted && (context.globalAliases.has(literal) ||
      environment.kind === 'available' && environment.globalAliases.has(literal))) return true;
    return !word.quoted && [...word.raw].some(char => '*?[{~('.includes(char));
  }
  if (word.quoteKind !== 'double') return true;
  return word.parts.some(part => part.kind === 'parameterExpansion' &&
    (simpleParameter(part.raw) === null || simpleParameter(part.raw) === '@'));
}

function argumentDiagnostics(command: SimpleCommandNode, definition: FunctionDefinitionNode,
  context: ResolutionContext, mapRange: (range: SourceRange) => SourceRange): readonly Diagnostics[] {
  const parameters = documentationOf(definition)?.parameters ?? [];
  if (!parameters.length || command.arguments.some(word => uncertainWord(word, context))) return [];
  const named = new Set(parameters.filter(parameter => parameter.kind === 'namedParameterDoc').map(parameter => parameter.name));
  const present = new Set<string>();
  let positional = 0;
  for (const word of command.arguments) {
    const key = namedKey(word);
    if (key && named.has(key)) present.add(key);
    else positional += 1;
  }
  const diagnostics: Diagnostics[] = [];
  const range = protocolRange(mapRange(command.commandName?.range ?? command.range));
  const missing = parameters.filter(parameter =>
    parameter.kind === 'positionalParameterDoc' && !parameter.optional && parameter.position > positional);
  if (missing.length) diagnostics.push({ severity: DiagnosticSeverity.Error, code: 'missing-positional-argument',
    range, source: 'z-ls', message: 'Missing required argument(s): ' +
      missing.map(parameter => parameter.kind === 'positionalParameterDoc' ? '$' + parameter.position : '').join(', ') });
  for (const parameter of parameters) {
    if (parameter.kind === 'namedParameterDoc' && !parameter.optional && !present.has(parameter.name)) {
      diagnostics.push({ severity: DiagnosticSeverity.Error, code: 'missing-named-argument', range, source: 'z-ls',
        message: 'Missing required named argument: ' + parameter.name });
    }
  }
  return diagnostics;
}

export type CallScope = { readonly file: ZshFileHydration; readonly offset: number };
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
function localDefinitions(snapshot: FunctionSnapshot, file: ZshFileHydration): ReadonlyMap<string, readonly FunctionDefinitionNode[]> {
  const local = new Map<string, FunctionDefinitionNode[]>();
  if (snapshot.hydrator.files.get(file.file) === file) return local;
  for (const definition of new Set(file.functions.map(entry => entry.definition))) {
    for (const word of definition.names) {
      const name = literalWord(word);
      if (!name) continue;
      const group = local.get(name) ?? [];
      group.push(definition);
      local.set(name, group);
    }
  }
  return local;
}

/** 既存の前方参照の動作を保ちながら、直前にある最も近い定義を優先する。 */
function localDefinition(definitions: ReadonlyMap<string, readonly FunctionDefinitionNode[]>, name: string, offset: number) {
  const candidates = definitions.get(name) ?? [];
  return candidates.findLast(definition => definition.range.start.offset <= offset) ?? candidates[0];
}

/** 解決済みの関数参照をコード引数の解析でも再利用し、報告する位置だけを変換する。 */
export function analyzeCalls(snapshot: FunctionSnapshot, file: ZshFileHydration,
  commands: readonly SimpleCommandNode[], context: ResolutionContext, options: CallAnalysisOptions = {}): CallAnalysis {
  const diagnostics: Diagnostics[] = [];
  const targets = new Map<SimpleCommandNode, FunctionDefinitionNode>();
  const classTargets = new Map<SimpleCommandNode, readonly ClassCommandTarget[]>();
  const local = localDefinitions(snapshot, file);
  const scopes = (options.scopes ?? []).map(scope => ({ ...scope, definitions: localDefinitions(snapshot, scope.file) }));
  const origin = scopes.at(-1);
  const mapRange = options.mapRange ?? (range => range);
  const incomplete = file.lexerDiagnostics.length > 0 || file.parserDiagnostics.length > 0;
  for (const command of commands) {
    const word = command.commandName?.word;
    const name = word && literalWord(word);
    if (!word || !name) continue;
    if (!word.quoted && word.raw.startsWith('=') || uncertainWord(word, context)) continue;
    const inspect = command.precommandModifiers.some(modifier => modifier.type === 'command' &&
      modifier.options.some(option => option.name.includes('v') || option.name.includes('V')));
    if (inspect || alias(name, word, context)) continue;
    const inherited = scopes.map(scope => localDefinition(scope.definitions, name, scope.offset)).find(target => target !== undefined);
    const target = functionCommand(command) ? localDefinition(local, name, word.range.start.offset) ?? inherited ??
      resolveFunction(snapshot, name, { file: origin?.file ?? file, offset: origin?.offset ?? word.range.start.offset })?.definition : null;
    const generated = functionCommand(command) ? context.classCommands.get(name) : undefined;
    if (target) {
      targets.set(command, target);
      if (!incomplete) {
        for (const diagnostic of argumentDiagnostics(command, target, context, mapRange)) {
          if (!options.ignores || !ignored(options.ignores, word.range.start.line, diagnostic.code)) diagnostics.push(diagnostic);
        }
      }
    } else if (generated) {
      classTargets.set(command, generated);
    } else if (context.autoloads.has(name) && functionCommand(command)) {
      continue;
    } else if (shellKnown(name, command, context) === false &&
      (!options.ignores || !ignored(options.ignores, word.range.start.line, 'undefined-command'))) {
      diagnostics.push({ severity: DiagnosticSeverity.Error, code: 'undefined-command',
        range: protocolRange(mapRange(word.range)), source: 'z-ls',
        message: name + ' is not defined in the project or shell environment.' });
    }
  }
  return { diagnostics, targets, classTargets };
}

/** 関数の参照先を必要としない呼び出し元向けに、既存の診断のみを返すAPIを保つ。 */
export function callDiagnostics(snapshot: FunctionSnapshot, file: ZshFileHydration,
  commands: readonly SimpleCommandNode[], context: ResolutionContext): readonly Diagnostics[] {
  return analyzeCalls(snapshot, file, commands, context).diagnostics;
}
