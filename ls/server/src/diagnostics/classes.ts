import type { FunctionDefinitionNode, SimpleCommandNode } from '../zshParser/ast';
import { literalWord } from '../refreshFunctions/word';

export type ClassDeclarations = {
  readonly definitions: ReadonlyMap<string, ReadonlySet<string>>;
  readonly instances: ReadonlyMap<string, ReadonlySet<string>>;
};
export type ClassState = {
  readonly definitions: Map<string, ReadonlySet<string>>;
  readonly instances: Map<string, Set<string>>;
  pending?: {
    readonly name: string; readonly scope: FunctionDefinitionNode | undefined;
    readonly members: Set<string>; methodDepth?: number;
  };
};

export function createClassState(): ClassState {
  return { definitions: new Map(), instances: new Map() };
}

function identifier(value: string | null | undefined): value is string {
  return value !== null && value !== undefined && /^[A-Za-z_][A-Za-z0-9_]*$/.test(value) &&
    !value.startsWith('z_cls_') && !value.startsWith('__z_cls_');
}

export function classDeclaration(command: SimpleCommandNode, depth: number,
  scope: FunctionDefinitionNode | undefined, state: ClassState): void {
  const name = command.commandName && literalWord(command.commandName.word);
  const args = command.arguments.map(word => literalWord(word));
  const pending = state.pending;
  if (pending?.methodDepth !== undefined) {
    if (name === 'z.cls.fn.done' && scope === pending.scope && depth === pending.methodDepth) {
      delete pending.methodDepth;
    }
    return;
  }
  if (name === 'z.cls.new' && identifier(args[0]) && identifier(args[1]) && args.length === 2) {
    const classes = state.instances.get(args[1]) ?? new Set<string>();
    classes.add(args[0]);
    state.instances.set(args[1], classes);
  } else if (name === 'z.cls.draw' && identifier(args[0]) && args.length === 1 && !pending) {
    state.pending = { name: args[0], scope, members: new Set() };
  } else if (pending && scope === pending.scope) {
    if (name === 'z.cls.attr' && identifier(args[0]) && args.length === 2) {
      pending.members.add(args[0] + '.get');
      pending.members.add(args[0] + '.set');
    } else if (name === 'z.cls.fn' && identifier(args[0]) && args.length >= 1 && args.length <= 2) {
      pending.members.add(args[0]);
      if (args.length === 1) pending.methodDepth = depth;
    } else if (name === 'z.cls.drew' && args.length === 0) {
      state.definitions.set(pending.name, pending.members);
      delete state.pending;
    } else if (name === 'z.cls.abort') {
      delete state.pending;
    }
  }
}

export function classCommands(declarations: readonly ClassDeclarations[]): ReadonlySet<string> {
  const definitions = new Map(declarations.flatMap(file => [...file.definitions]));
  const commands = new Set<string>();
  for (const file of declarations) {
    for (const [instance, classes] of file.instances) {
      for (const name of classes) {
        for (const member of definitions.get(name) ?? []) commands.add(instance + '.' + member);
      }
    }
  }
  return commands;
}
