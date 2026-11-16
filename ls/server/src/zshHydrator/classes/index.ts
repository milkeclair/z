import type { AstNode, FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import { findAll, mapAst } from '../../zshParser/ast';
import { collectClassInformation } from './collect';
import type {
  ClassAttribute,
  ClassDefinition,
  ClassFileHydration,
  ClassInformation,
  ClassInstance,
  ClassMethod,
  ClassMethodScope,
  ClassScopeLocation,
  HydratedClassCommand,
} from './types';

export type * from './types';

type DefinitionGroup = {
  readonly definition: Omit<ClassDefinition, 'attributes' | 'methods'>;
  readonly attributes: ClassAttribute[];
  readonly methods: ClassMethod[];
};

/** Narrow the attachment through its class role discriminator. */
export function isHydratedClassCommand(node: SimpleCommandNode): node is HydratedClassCommand {
  if (!('hydration' in node) || typeof node.hydration !== 'object' || node.hydration === null) {
    return false;
  }

  const information = node.hydration;

  return 'kind' in information && 'name' in information && typeof information.name === 'string' &&
    (information.kind === 'classDefinition' || information.kind === 'classAttribute' ||
      information.kind === 'classMethod' || information.kind === 'classInstance');
}

/** Expose class meaning without changing the generic syntax node types. */
export function classInformationOf(node: SimpleCommandNode): ClassInformation | null {
  return isHydratedClassCommand(node) ? node.hydration : null;
}

/** Attach class meaning while retaining every native syntax kind, token and range. */
export function hydrateClasses(ast: FileNode): FileNode {
  const information = collectClassInformation(ast);
  if (information.size === 0) return ast;

  return mapAst(ast, (node: AstNode): AstNode => {
    if (node.kind !== 'simpleCommand') return node;

    const value = information.get(node.range.start.offset);
    if (value) {
      const hydrated: HydratedClassCommand = { ...node, hydration: value };
      return hydrated;
    }

    if (isHydratedClassCommand(node)) {
      const { hydration, ...syntax } = node;
      return syntax;
    }

    return node;
  });
}

/** Resolve an attachment's lexical owner against the final enriched syntax nodes. */
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

/** Group member indexes under definition nodes from the returned AST. */
function definitionGroups(ast: FileNode, commands: readonly HydratedClassCommand[],
  functions: ReadonlyMap<number, FunctionDefinitionNode>): Map<number, DefinitionGroup> {
  const groups = new Map<number, DefinitionGroup>();

  for (const command of commands) {
    const information = command.hydration;
    const nameNode = command.arguments[0];
    if (information.kind !== 'classDefinition' || !nameNode) continue;

    const scope = information.scope.kind === 'function'
      ? functions.get(information.scope.offset) ?? null
      : null;

    groups.set(command.range.start.offset, {
      definition: {
        kind: 'classDefinition',
        name: information.name,
        declaration: command,
        nameNode,
        file: ast,
        scope,
        state: information.state,
        range: information.range,
      },
      attributes: [],
      methods: [],
    });
  }

  return groups;
}

/** Build indexes only after enrichment, so declarations, words and scopes refer to the returned AST. */
export function classesFromAst(ast: FileNode): ClassFileHydration {
  const commands = findAll(ast, 'simpleCommand').filter(isHydratedClassCommand);
  if (commands.length === 0) {
    return { definitions: [], instances: [], methodScopes: new Map() };
  }

  const commandByOffset = new Map(commands.map(node => [node.range.start.offset, node]));
  const functions = new Map(findAll(ast, 'functionDefinition').map(node => [node.range.start.offset, node]));
  const groups = definitionGroups(ast, commands, functions);
  const instances: ClassInstance[] = [];

  for (const command of commands) {
    const information = command.hydration;
    const [nameNode, value] = command.arguments;
    if (!nameNode) continue;

    if (information.kind === 'classAttribute' && value) {
      groups.get(information.classOffset)?.attributes.push({
        kind: 'classAttribute',
        name: information.name,
        declaration: command,
        nameNode,
        defaultValue: value,
      });
    } else if (information.kind === 'classMethod') {
      if (information.body.kind === 'inline' && !value) continue;

      const body: ClassMethod['body'] = information.body.kind === 'inline'
        ? { kind: 'inline', value }
        : information.body;

      groups.get(information.classOffset)?.methods.push({
        kind: 'classMethod',
        name: information.name,
        declaration: command,
        nameNode,
        body,
      });
    } else if (information.kind === 'classInstance' && value) {
      const scope = instanceScope(information.scope, functions, commandByOffset);
      if (!scope) continue;

      instances.push({
        kind: 'classInstance',
        name: information.name,
        className: information.className,
        declaration: command,
        classNameNode: nameNode,
        nameNode: value,
        scope,
        file: ast,
      });
    }
  }

  const definitions = [...groups.values()].map(group => ({
    ...group.definition,
    attributes: group.attributes,
    methods: group.methods,
  }));
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

  return { definitions, instances, methodScopes };
}

/** Find method parameter ownership without interpreting class commands again during diagnostics. */
export function classMethodAt(classes: ClassFileHydration,
  scope: FunctionDefinitionNode | null, offset: number): ClassMethod | null {
  const methods = classes.methodScopes.get(scope) ?? [];
  let low = 0;
  let high = methods.length - 1;

  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const entry = methods[middle];

    if (offset < entry.range.start.offset) {
      high = middle - 1;
    } else if (offset >= entry.range.end.offset) {
      low = middle + 1;
    } else {
      return entry.method;
    }
  }

  return null;
}
