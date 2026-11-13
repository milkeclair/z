import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import { walk } from '../zshParser/ast';
import type { ZshFileHydration } from '../zshHydrator';
import { documentationOf } from '../zshHydrator';
import { DiagnosticSeverity } from '../vscode_type';
import type { Diagnostics } from './type';
import { protocolRange } from '../connection/ast/cursor';
import { literalWord } from '../refreshFunctions/word';
import { formatDiagnostics } from './format';

export type Declarations = {
  readonly aliases: ReadonlySet<string>; readonly globalAliases: ReadonlySet<string>;
  readonly suffixAliases: ReadonlySet<string>; readonly autoloads: ReadonlySet<string>;
};
export type FileFacts = {
  readonly calls: readonly SimpleCommandNode[]; readonly base: readonly Diagnostics[];
  readonly declarations: Declarations;
};
type Usage = {
  readonly definition: FunctionDefinitionNode; readonly depth: number;
  readonly positions: Set<number>; readonly names: Set<string>;
  all: boolean; uncertain: boolean;
};

function identifier(name: string): boolean {
  return name.length > 0 && [...name].every((char, index) => char === '_' ||
    char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' ||
    index > 0 && char >= '0' && char <= '9');
}

export function simpleParameter(raw: string): string | null {
  const name = raw[1] === '{' && raw.endsWith('}') ? raw.slice(2, -1) : raw.slice(1);
  if (!raw.startsWith('$')) return null;
  if (name === '@' || name === '*' || identifier(name) ||
    name.length > 0 && [...name].every(char => char >= '0' && char <= '9')) return name;
  const bracket = name.indexOf('[');
  return bracket > 0 && name.endsWith(']') && identifier(name.slice(0, bracket)) &&
    identifier(name.slice(bracket + 1, -1)) ? name.slice(bracket + 1, -1) : null;
}

function use(usage: Usage, name: string): void {
  if (name === '@' || name === '*') usage.all = true;
  else if ([...name].every(char => char >= '0' && char <= '9')) usage.positions.add(Number(name));
  else usage.names.add(name);
}

function wordUsage(word: WordNode, usage: Usage): void {
  for (const part of word.parts) {
    if (part.kind === 'variableReference') {
      use(usage, part.name.value);
      const rest = word.raw.slice(part.range.end.offset - word.range.start.offset);
      const close = rest.indexOf(']');
      if (rest.startsWith('[') && close > 1 && identifier(rest.slice(1, close))) use(usage, rest.slice(1, close));
    } else if (part.kind === 'parameterExpansion') {
      const name = simpleParameter(part.raw);
      if (name === null) usage.uncertain = true;
      else use(usage, name);
    } else if (part.kind === 'arithmeticExpansion') usage.uncertain = true;
  }
}

function declarations(command: SimpleCommandNode, sets: {
  aliases: Set<string>; globalAliases: Set<string>; suffixAliases: Set<string>; autoloads: Set<string>;
}): void {
  const name = command.commandName && literalWord(command.commandName.word);
  if (name === 'autoload') {
    for (const word of command.arguments) {
      const value = literalWord(word);
      if (value && !value.startsWith('-') && !value.startsWith('+')) sets.autoloads.add(value.slice(value.lastIndexOf('/') + 1));
    }
  } else if (name === 'alias') {
    let target = sets.aliases;
    for (const word of command.arguments) {
      const value = literalWord(word);
      if (!value) continue;
      if (value.startsWith('-')) {
        if (value.includes('g')) target = sets.globalAliases;
        if (value.includes('s')) target = sets.suffixAliases;
        continue;
      }
      const equals = value.indexOf('=');
      if (equals > 0) target.add(value.slice(0, equals));
    }
  }
}

export function collectFileFacts(file: ZshFileHydration): FileFacts {
  const calls: SimpleCommandNode[] = [];
  const usages: Usage[] = [];
  const active: Usage[] = [];
  const sets = { aliases: new Set<string>(), globalAliases: new Set<string>(),
    suffixAliases: new Set<string>(), autoloads: new Set<string>() };
  walk(file.ast, (node, depth) => {
    while (active.length && active[active.length - 1].depth >= depth) active.pop();
    if (node.kind === 'functionDefinition') {
      const usage: Usage = { definition: node, depth, positions: new Set(), names: new Set(), all: false,
        uncertain: file.parserDiagnostics.length > 0 || file.lexerDiagnostics.length > 0 };
      usages.push(usage); active.push(usage);
    }
    const current = active.at(-1);
    if (node.kind === 'simpleCommand') {
      if (node.commandName) calls.push(node);
      declarations(node, sets);
      if (current && node.commandName && literalWord(node.commandName.word) === 'z.arg.named') {
        const word = node.arguments[0];
        const name = word && literalWord(word);
        if (name) use(current, name);
      }
    }
    if (!current) return;
    if (node.kind === 'word') wordUsage(node, current);
    if (node.kind === 'opaqueCommand' || node.kind === 'unknown' ||
      node.kind === 'hereDocument' && !node.quoted) current.uncertain = true;
  });
  const base = [...formatDiagnostics(file)];
  for (const usage of usages) {
    if (usage.all || usage.uncertain) continue;
    for (const parameter of documentationOf(usage.definition)?.parameters ?? []) {
      const used = parameter.kind === 'positionalParameterDoc' ? usage.positions.has(parameter.position) :
        parameter.kind === 'namedParameterDoc' ? usage.names.has(parameter.name) : false;
      if (used) continue;
      const name = parameter.kind === 'positionalParameterDoc' ? '$' + parameter.position :
        parameter.kind === 'namedParameterDoc' ? parameter.name : '$' + parameter.parameter;
      base.push({ severity: DiagnosticSeverity.Warning, code: 'unused-argument',
        range: protocolRange(parameter.markerRange), message: "Argument '" + name + "' is never used.", source: 'z-ls' });
    }
  }
  for (const diagnostic of file.lexerDiagnostics) base.push({ severity: DiagnosticSeverity.Error,
    code: diagnostic.kind, range: protocolRange(diagnostic.range), message: diagnostic.message, source: 'z-ls/lexer' });
  for (const diagnostic of file.parserDiagnostics) base.push({ severity: DiagnosticSeverity.Error,
    code: diagnostic.kind, range: protocolRange(diagnostic.range), message: diagnostic.message, source: 'z-ls/parser' });
  for (const diagnostic of file.hydrationDiagnostics) base.push({ severity: DiagnosticSeverity.Warning,
    code: diagnostic.kind, range: protocolRange(diagnostic.range), message: diagnostic.message, source: 'z-ls/documentation' });
  return { calls, base, declarations: sets };
}
