import type { FunctionDefinitionNode, SimpleCommandNode } from '../zshParser/ast';
import { literalWord } from '../refreshFunctions/word';

export type ClassDeclarations = {
  readonly definitions: ReadonlyMap<string, ReadonlySet<string>>;
  readonly instances: ReadonlyMap<string, ReadonlySet<string>>;
};
type ClassDefinition = {
  readonly name: string; readonly scope: FunctionDefinitionNode | undefined;
  readonly members: ReadonlySet<string>;
};
type ClassCapture =
  | { readonly kind: 'definition'; readonly definition: ClassDefinition }
  | { readonly kind: 'method'; readonly definition: ClassDefinition; readonly depth: number };
export type ClassState = ClassDeclarations & { readonly pending: ClassCapture | null };

export function createClassState(): ClassState {
  return { definitions: new Map(), instances: new Map(), pending: null };
}

function identifier(value: string | null | undefined): value is string {
  return value !== null && value !== undefined && /^[A-Za-z_][A-Za-z0-9_]*$/.test(value) &&
    !value.startsWith('z_cls_') && !value.startsWith('__z_cls_');
}

export function classDeclaration(command: SimpleCommandNode, depth: number,
  scope: FunctionDefinitionNode | undefined, state: ClassState): ClassState {
  const name = command.commandName && literalWord(command.commandName.word);
  const args = command.arguments.map(word => literalWord(word));
  const pending = state.pending;
  if (pending?.kind === 'method') {
    return name === 'z.cls.fn.done' && scope === pending.definition.scope && depth === pending.depth ?
      { ...state, pending: { kind: 'definition', definition: pending.definition } } : state;
  }
  if (name === 'z.cls.new' && identifier(args[0]) && identifier(args[1]) && args.length === 2) {
    const instances = new Map(state.instances);
    instances.set(args[1], new Set([...(instances.get(args[1]) ?? []), args[0]]));
    return { ...state, instances };
  }
  if (name === 'z.cls.draw' && identifier(args[0]) && args.length === 1 && !pending) {
    return { ...state, pending: { kind: 'definition', definition: { name: args[0], scope, members: new Set() } } };
  }
  if (!pending || scope !== pending.definition.scope) return state;

  const definition = pending.definition;
  if (name === 'z.cls.attr' && identifier(args[0]) && args.length === 2) {
    const members = new Set([...definition.members, args[0] + '.get', args[0] + '.set']);
    return { ...state, pending: { kind: 'definition', definition: { ...definition, members } } };
  }
  if (name === 'z.cls.fn' && identifier(args[0]) && args.length >= 1 && args.length <= 2) {
    const next = { ...definition, members: new Set([...definition.members, args[0]]) };
    return { ...state, pending: args.length === 1 ?
      { kind: 'method', definition: next, depth } : { kind: 'definition', definition: next } };
  }
  if (name === 'z.cls.drew' && args.length === 0) {
    const definitions = new Map(state.definitions);
    definitions.set(definition.name, definition.members);
    return { ...state, definitions, pending: null };
  }
  return name === 'z.cls.abort' ? { ...state, pending: null } : state;
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
