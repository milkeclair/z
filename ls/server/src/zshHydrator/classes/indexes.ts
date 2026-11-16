import type { FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import type {
  ClassAttribute, ClassDefinition, ClassFileHydration, ClassInstance,
  ClassMethod, ClassMethodScope, ClassScopeLocation, HydratedClassCommand,
} from './types';

type MemberGroup = {
  readonly attributes: readonly ClassAttribute[];
  readonly methods: readonly ClassMethod[];
};
type LocatedMember = {
  readonly classOffset: number;
  readonly member: ClassAttribute | ClassMethod;
};

/** Retain a member's final syntax nodes without copying its body or value. */
function memberFromCommand(command: HydratedClassCommand): LocatedMember | null {
  const information = command.hydration;
  const [nameNode, value] = command.arguments;
  if (!nameNode) return null;

  const base = { name: information.name, declaration: command, nameNode };
  if (information.kind === 'classAttribute' && value) {
    return {
      classOffset: information.classOffset,
      member: { ...base, kind: 'classAttribute', defaultValue: value },
    };
  }

  if (information.kind !== 'classMethod' || information.body.kind === 'inline' && !value) return null;

  const body: ClassMethod['body'] = information.body.kind === 'inline'
    ? { kind: 'inline', value }
    : information.body;

  return { classOffset: information.classOffset, member: { ...base, kind: 'classMethod', body } };
}

/** Build fresh member groups; input commands and their existing indexes stay unchanged. */
export function membersFromCommands(commands: readonly HydratedClassCommand[]): ReadonlyMap<number, MemberGroup> {
  const groups = new Map<number, { attributes: ClassAttribute[]; methods: ClassMethod[] }>();

  for (const command of commands) {
    const located = memberFromCommand(command);
    if (!located) continue;

    const group = groups.get(located.classOffset) ?? { attributes: [], methods: [] };
    if (located.member.kind === 'classAttribute') {
      group.attributes.push(located.member);
    } else {
      group.methods.push(located.member);
    }
    groups.set(located.classOffset, group);
  }

  return groups;
}

/** Join a definition to its final native function owner and freshly built member group. */
function definitionFromCommand(ast: FileNode, command: HydratedClassCommand,
  functions: ReadonlyMap<number, FunctionDefinitionNode>,
  members: ReadonlyMap<number, MemberGroup>): ClassDefinition | null {
  const information = command.hydration;
  const nameNode = command.arguments[0];
  if (information.kind !== 'classDefinition' || !nameNode) return null;

  const scope = information.scope.kind === 'function' ? functions.get(information.scope.offset) ?? null : null;
  const group = members.get(command.range.start.offset);

  return {
    kind: 'classDefinition',
    name: information.name,
    declaration: command,
    nameNode,
    file: ast,
    scope,
    state: information.state,
    range: information.range,
    attributes: group?.attributes ?? [],
    methods: group?.methods ?? [],
  };
}

/** Collect definitions in native syntax order, retaining incomplete and aborted entries. */
export function definitionsFromCommands(ast: FileNode, commands: readonly HydratedClassCommand[],
  functions: ReadonlyMap<number, FunctionDefinitionNode>,
  members: ReadonlyMap<number, MemberGroup>): readonly ClassDefinition[] {
  return commands.map(command => definitionFromCommand(ast, command, functions, members))
    .filter((definition): definition is ClassDefinition => definition !== null);
}

/** Resolve lexical ownership only against the final enriched syntax nodes. */
function instanceScope(location: ClassScopeLocation,
  functions: ReadonlyMap<number, FunctionDefinitionNode>,
  commands: ReadonlyMap<number, SimpleCommandNode>): ClassInstance['scope'] | null {
  if (location.kind === 'file') return { kind: 'file' };

  if (location.kind === 'function') {
    const declaration = functions.get(location.offset);
    return declaration ? { kind: 'function', declaration } : null;
  }

  const declaration = commands.get(location.offset);
  return declaration ? { kind: 'classMethod', declaration } : null;
}

/** Bind an instance's class/name words to its final lexical owner. */
function instanceFromCommand(ast: FileNode, command: HydratedClassCommand,
  functions: ReadonlyMap<number, FunctionDefinitionNode>,
  commands: ReadonlyMap<number, SimpleCommandNode>): ClassInstance | null {
  const information = command.hydration;
  const [classNameNode, nameNode] = command.arguments;
  if (information.kind !== 'classInstance' || !classNameNode || !nameNode) return null;

  const scope = instanceScope(information.scope, functions, commands);
  if (!scope) return null;

  return {
    kind: 'classInstance',
    name: information.name,
    className: information.className,
    declaration: command,
    classNameNode,
    nameNode,
    scope,
    file: ast,
  };
}

/** Collect independent bindings without changing commands or other file indexes. */
export function instancesFromCommands(ast: FileNode, commands: readonly HydratedClassCommand[],
  functions: ReadonlyMap<number, FunctionDefinitionNode>): readonly ClassInstance[] {
  const commandByOffset = new Map(commands.map(node => [node.range.start.offset, node]));

  return commands.map(command => instanceFromCommand(ast, command, functions, commandByOffset))
    .filter((instance): instance is ClassInstance => instance !== null);
}

/** Index block ranges for argument ownership without interpreting directives again. */
export function methodScopesFromDefinitions(definitions: readonly ClassDefinition[]): ClassFileHydration['methodScopes'] {
  const methodScopes = new Map<FunctionDefinitionNode | null, ClassMethodScope[]>();

  for (const definition of definitions) {
    for (const method of definition.methods) {
      if (method.body.kind !== 'block') continue;

      const scopes = methodScopes.get(definition.scope) ?? [];
      scopes.push({ method, range: method.body.range });
      methodScopes.set(definition.scope, scopes);
    }
  }

  for (const scopes of methodScopes.values()) {
    scopes.sort((left, right) => left.range.start.offset - right.range.start.offset);
  }

  return methodScopes;
}
