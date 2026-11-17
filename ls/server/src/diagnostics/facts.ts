import { List, OrderedMap, OrderedSet } from 'immutable';
import { protocolRange } from '../connection/ast/cursor';
import { literalWord } from '../refreshFunctions/word';
import { again, done, loop } from '../util/loop';
import { DiagnosticSeverity } from '../vscode_type';
import type { ZshFileHydration } from '../zshHydrator';
import { documentationOf } from '../zshHydrator';
import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import { foldAst } from '../zshParser/ast';
import { formatDiagnostics } from './format';
import { moduleBuiltins } from './modules';
import type { Diagnostics } from './type';

export type Declarations = {
  readonly aliases: ReadonlySet<string>;
  readonly globalAliases: ReadonlySet<string>;
  readonly suffixAliases: ReadonlySet<string>;
  readonly autoloads: ReadonlySet<string>;
  readonly builtins: ReadonlySet<string>;
};
export type FileFacts = {
  readonly calls: readonly SimpleCommandNode[];
  readonly base: readonly Diagnostics[];
  readonly declarations: Declarations;
};
type DeclarationSets = {
  readonly aliases: OrderedSet<string>;
  readonly globalAliases: OrderedSet<string>;
  readonly suffixAliases: OrderedSet<string>;
  readonly autoloads: OrderedSet<string>;
  readonly builtins: OrderedSet<string>;
};
type Usage = {
  readonly definition: FunctionDefinitionNode;
  readonly depth: number;
  readonly positions: OrderedSet<number>;
  readonly names: OrderedSet<string>;
  readonly all: boolean;
  readonly uncertain: boolean;
};
type Scope = { readonly definition: FunctionDefinitionNode; readonly depth: number };
type FactsProgress = {
  readonly calls: List<SimpleCommandNode>;
  readonly usages: OrderedMap<FunctionDefinitionNode, Usage>;
  readonly active: List<Scope>;
  readonly declarations: DeclarationSets;
};
function identifier(name: string): boolean {
  return (
    name.length > 0 &&
    [...name].every(
      (char, index) =>
        char === '_' ||
        (char >= 'a' && char <= 'z') ||
        (char >= 'A' && char <= 'Z') ||
        (index > 0 && char >= '0' && char <= '9'),
    )
  );
}
export function simpleParameter(raw: string): string | null {
  const name = raw[1] === '{' && raw.endsWith('}') ? raw.slice(2, -1) : raw.slice(1);
  if (!raw.startsWith('$')) {
    return null;
  }
  if (
    name === '@' ||
    name === '*' ||
    identifier(name) ||
    (name.length > 0 && [...name].every((char) => char >= '0' && char <= '9'))
  ) {
    return name;
  }
  const bracket = name.indexOf('[');
  return bracket > 0 &&
    name.endsWith(']') &&
    identifier(name.slice(0, bracket)) &&
    identifier(name.slice(bracket + 1, -1))
    ? name.slice(bracket + 1, -1)
    : null;
}
function use(usage: Usage, name: string): Usage {
  if (name === '@' || name === '*') {
    return { ...usage, all: true };
  }
  return [...name].every((char) => char >= '0' && char <= '9')
    ? { ...usage, positions: usage.positions.add(Number(name)) }
    : { ...usage, names: usage.names.add(name) };
}
function wordUsage(word: WordNode, usage: Usage): Usage {
  return word.parts.reduce((previous, part) => {
    if (part.kind === 'variableReference') {
      const current = use(previous, part.name.value);
      const rest = word.raw.slice(part.range.end.offset - word.range.start.offset),
        close = rest.indexOf(']');
      return rest.startsWith('[') && close > 1 && identifier(rest.slice(1, close))
        ? use(current, rest.slice(1, close))
        : current;
    }
    if (part.kind === 'parameterExpansion') {
      const name = simpleParameter(part.raw);
      return name === null ? { ...previous, uncertain: true } : use(previous, name);
    }
    return part.kind === 'arithmeticExpansion' ? { ...previous, uncertain: true } : previous;
  }, usage);
}
function collectDeclarations(command: SimpleCommandNode, sets: DeclarationSets): DeclarationSets {
  const name = command.commandName && literalWord(command.commandName.word);
  if (name === 'autoload') {
    const names = command.arguments.flatMap((word) => {
      const value = literalWord(word);
      return value && !value.startsWith('-') && !value.startsWith('+')
        ? [value.slice(value.lastIndexOf('/') + 1)]
        : [];
    });
    return { ...sets, autoloads: sets.autoloads.union(names) };
  }
  if (name === 'zmodload') {
    return { ...sets, builtins: sets.builtins.union(moduleBuiltins(command)) };
  }
  if (name !== 'alias') {
    return sets;
  }
  type Target = 'aliases' | 'globalAliases' | 'suffixAliases';
  return command.arguments.reduce<{ readonly target: Target; readonly sets: DeclarationSets }>(
    (previous, word) => {
      const value = literalWord(word);
      if (!value) {
        return previous;
      }
      if (value.startsWith('-')) {
        const target = value.includes('s')
          ? 'suffixAliases'
          : value.includes('g')
            ? 'globalAliases'
            : previous.target;
        return { ...previous, target };
      }
      const equals = value.indexOf('=');
      return equals > 0
        ? {
            ...previous,
            sets: {
              ...previous.sets,
              [previous.target]: previous.sets[previous.target].add(value.slice(0, equals)),
            },
          }
        : previous;
    },
    { target: 'aliases', sets },
  ).sets;
}
function scopeUsage(
  file: ZshFileHydration,
  definition: FunctionDefinitionNode,
  depth: number,
): Usage {
  return {
    definition,
    depth,
    positions: OrderedSet(),
    names: OrderedSet(),
    all: false,
    uncertain: file.parserDiagnostics.length > 0 || file.lexerDiagnostics.length > 0,
  };
}
function unusedArguments(usage: Usage): readonly Diagnostics[] {
  if (usage.all || usage.uncertain) {
    return [];
  }
  return (documentationOf(usage.definition)?.parameters ?? []).flatMap(
    (parameter): readonly Diagnostics[] => {
      const used =
        parameter.kind === 'positionalParameterDoc'
          ? usage.positions.has(parameter.position)
          : parameter.kind === 'namedParameterDoc'
            ? usage.names.has(parameter.name)
            : false;
      if (used) {
        return [];
      }
      const name =
        parameter.kind === 'positionalParameterDoc'
          ? '$' + parameter.position
          : parameter.kind === 'namedParameterDoc'
            ? parameter.name
            : '$' + parameter.parameter;
      return [
        {
          severity: DiagnosticSeverity.Warning,
          code: 'unused-argument',
          range: protocolRange(parameter.markerRange),
          message: "Argument '" + name + "' is never used.",
          source: 'z-ls',
        },
      ];
    },
  );
}
export function collectFileFacts(file: ZshFileHydration): FileFacts {
  const initial: FactsProgress = {
    calls: List(),
    usages: OrderedMap(),
    active: List(),
    declarations: {
      aliases: OrderedSet(),
      globalAliases: OrderedSet(),
      suffixAliases: OrderedSet(),
      autoloads: OrderedSet(),
      builtins: OrderedSet(),
    },
  };
  const facts = foldAst(file.ast, initial, (previous, node, depth) => {
    const active = loop(previous.active, (scopes) => {
      const last = scopes.last();
      return last && last.depth >= depth ? again(scopes.pop()) : done(scopes);
    });
    const scoped: FactsProgress =
      node.kind === 'functionDefinition'
        ? {
            ...previous,
            active: active.push({ definition: node, depth }),
            usages: previous.usages.set(node, scopeUsage(file, node, depth)),
          }
        : { ...previous, active };
    const current = scoped.active.last();
    const declared: FactsProgress =
      node.kind === 'simpleCommand'
        ? {
            ...scoped,
            calls: node.commandName ? scoped.calls.push(node) : scoped.calls,
            declarations: collectDeclarations(node, scoped.declarations),
          }
        : scoped;
    const usage = current && declared.usages.get(current.definition);
    if (!usage) {
      return { state: declared };
    }
    const named =
      node.kind === 'simpleCommand' &&
      node.commandName &&
      literalWord(node.commandName.word) === 'z.arg.named'
        ? node.arguments[0] && literalWord(node.arguments[0])
        : null;
    const read = named ? use(usage, named) : usage;
    const words = node.kind === 'word' ? wordUsage(node, read) : read;
    const uncertain =
      node.kind === 'opaqueCommand' ||
      node.kind === 'unknown' ||
      (node.kind === 'hereDocument' && !node.quoted);
    return {
      state: {
        ...declared,
        usages: declared.usages.set(
          usage.definition,
          uncertain ? { ...words, uncertain: true } : words,
        ),
      },
    };
  });
  const base: readonly Diagnostics[] = [
    ...formatDiagnostics(file),
    ...facts.usages.valueSeq().flatMap(unusedArguments),
    ...file.lexerDiagnostics.map(
      (diagnostic): Diagnostics => ({
        severity: DiagnosticSeverity.Error,
        code: diagnostic.kind,
        range: protocolRange(diagnostic.range),
        message: diagnostic.message,
        source: 'z-ls/lexer',
      }),
    ),
    ...file.parserDiagnostics.map(
      (diagnostic): Diagnostics => ({
        severity: DiagnosticSeverity.Error,
        code: diagnostic.kind,
        range: protocolRange(diagnostic.range),
        message: diagnostic.message,
        source: 'z-ls/parser',
      }),
    ),
    ...file.hydrationDiagnostics.map(
      (diagnostic): Diagnostics => ({
        severity: DiagnosticSeverity.Warning,
        code: diagnostic.kind,
        range: protocolRange(diagnostic.range),
        message: diagnostic.message,
        source: 'z-ls/documentation',
      }),
    ),
  ];
  const sets = facts.declarations;
  return {
    calls: facts.calls.toArray(),
    base,
    declarations: {
      aliases: new Set(sets.aliases),
      globalAliases: new Set(sets.globalAliases),
      suffixAliases: new Set(sets.suffixAliases),
      autoloads: new Set(sets.autoloads),
      builtins: new Set(sets.builtins),
    },
  };
}
