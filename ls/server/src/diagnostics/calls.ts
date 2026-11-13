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
import type { ShellEnvironment } from './environment';
import type { Declarations } from './facts';
import { simpleParameter } from './facts';

export type ResolutionContext = Declarations & {
  readonly environment: ShellEnvironment; readonly projectRoot: string;
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
  if (builtin) return environment.builtins.has(name);
  const commandOnly = command.precommandModifiers.some(modifier => modifier.type === 'command');
  if (command.precommandModifiers.some(modifier => modifier.type === 'command' &&
    modifier.options.some(option => option.name.includes('p')))) return null;
  if (!commandOnly && environment.functions.has(name)) return true;
  if (name.includes('/')) return executable(name, context);
  return environment.commands.has(name) || (!commandOnly || environment.commandBuiltins) && environment.builtins.has(name) ||
    !commandOnly && (environment.functions.has(name) || context.autoloads.has(name));
}

function uncertainWord(word: WordNode, context: ResolutionContext): boolean {
  const environment = context.environment;
  const literal = literalWord(word);
  if (literal !== null) {
    if (!word.quoted && (context.globalAliases.has(literal) ||
      environment.kind === 'available' && environment.globalAliases.has(literal))) return true;
    return !word.quoted && [...word.raw].some(char => '*?[{~'.includes(char));
  }
  if (word.quoteKind !== 'double') return true;
  return word.parts.some(part => part.kind === 'parameterExpansion' &&
    (simpleParameter(part.raw) === null || simpleParameter(part.raw) === '@'));
}

function argumentDiagnostics(command: SimpleCommandNode, definition: FunctionDefinitionNode,
  context: ResolutionContext): readonly Diagnostics[] {
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
  const range = protocolRange(command.commandName?.range ?? command.range);
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

export function callDiagnostics(snapshot: FunctionSnapshot, file: ZshFileHydration,
  commands: readonly SimpleCommandNode[], context: ResolutionContext): readonly Diagnostics[] {
  const diagnostics: Diagnostics[] = [];
  const local = new Map<string, FunctionDefinitionNode[]>();
  if (snapshot.hydrator.files.get(file.file) !== file) {
    for (const definition of new Set(file.functions.map(entry => entry.definition))) {
      for (const word of definition.names) {
        const name = literalWord(word);
        if (name) {
          const group = local.get(name) ?? [];
          group.push(definition);
          local.set(name, group);
        }
      }
    }
  }
  const incomplete = file.lexerDiagnostics.length > 0 || file.parserDiagnostics.length > 0;
  for (const command of commands) {
    const word = command.commandName?.word;
    const name = word && literalWord(word);
    if (!word || !name) continue;
    if (!word.quoted && word.raw.startsWith('=') || uncertainWord(word, context)) continue;
    const inspect = command.precommandModifiers.some(modifier => modifier.type === 'command' &&
      modifier.options.some(option => option.name.includes('v') || option.name.includes('V')));
    if (inspect || alias(name, word, context)) continue;
    const definitions = local.get(name) ?? [];
    const preceding = definitions.findLast(definition => definition.range.start.offset <= word.range.start.offset);
    const target = functionCommand(command) ? preceding ?? definitions[0] ?? resolveFunction(snapshot, name,
      { file, offset: word.range.start.offset })?.definition : null;
    if (target) {
      if (!incomplete) {
        for (const diagnostic of argumentDiagnostics(command, target, context)) diagnostics.push(diagnostic);
      }
    } else if (context.autoloads.has(name) && functionCommand(command)) {
      continue;
    } else if (shellKnown(name, command, context) === false) {
      diagnostics.push({ severity: DiagnosticSeverity.Error, code: 'undefined-command',
        range: protocolRange(word.range), source: 'z-ls',
        message: name + ' is not defined in the project or shell environment.' });
    }
  }
  return diagnostics;
}
