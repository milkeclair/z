import type { AstNode, FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import { findAll, mapAst } from '../../zshParser/ast';
import { collectClassInformation } from './collect';
import type { ClassInformation, ClassFileHydration, ClassDefinition, ClassAttribute, ClassMethod,
  ClassInstance, HydratedClassCommand } from './types';
export type * from './types';

/** Narrow the attachment through its class role discriminator. */
export function isHydratedClassCommand(node: SimpleCommandNode): node is HydratedClassCommand {
  if (!('hydration' in node) || typeof node.hydration !== 'object' || node.hydration === null) return false;
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

/** Build indexes only after enrichment, so every declaration/word/scope refers to the returned AST. */
export function classesFromAst(ast: FileNode): ClassFileHydration {
  const commands = findAll(ast, 'simpleCommand').filter(isHydratedClassCommand);
  if (commands.length === 0) return { definitions: [], instances: [], methodScopes: new Map() };
  const commandByOffset = new Map(commands.map(node => [node.range.start.offset, node]));
  const functions = new Map(findAll(ast, 'functionDefinition').map(node => [node.range.start.offset, node]));
  const groups = new Map<number, { definition: Omit<ClassDefinition, 'attributes' | 'methods'>;
    attributes: ClassAttribute[]; methods: ClassMethod[] }>();
  for (const command of commands) {
    const information = classInformationOf(command);
    if (information?.kind !== 'classDefinition' || !command.arguments[0]) continue;
    groups.set(command.range.start.offset, { definition: { kind: 'classDefinition', name: information.name,
      declaration: command, nameNode: command.arguments[0], file: ast,
      scope: information.scope.kind === 'function' ? functions.get(information.scope.offset) ?? null : null,
      state: information.state, range: information.range }, attributes: [], methods: [] });
  }
  const instances: ClassInstance[] = [];
  for (const command of commands) {
    const information = classInformationOf(command);
    if (!information) continue;
    const [nameNode, value] = command.arguments;
    if (!nameNode) continue;
    if (information.kind === 'classAttribute') {
      if (value) groups.get(information.classOffset)?.attributes.push({ kind: 'classAttribute', name: information.name,
        declaration: command, nameNode, defaultValue: value });
    } else if (information.kind === 'classMethod') {
      if (information.body.kind === 'inline' && !value) continue;
      groups.get(information.classOffset)?.methods.push({ kind: 'classMethod', name: information.name,
        declaration: command, nameNode, body: information.body.kind === 'inline' ?
          { kind: 'inline', value } : information.body });
    } else if (information.kind === 'classInstance' && value) {
      const location = information.scope;
      const ownerFunction = location.kind === 'function' ? functions.get(location.offset) : null;
      const ownerMethod = location.kind === 'classMethod' ? commandByOffset.get(location.offset) : null;
      if (location.kind === 'function' && !ownerFunction || location.kind === 'classMethod' && !ownerMethod) continue;
      const scope: ClassInstance['scope'] = ownerFunction ? { kind: 'function', declaration: ownerFunction } :
        ownerMethod ? { kind: 'classMethod', declaration: ownerMethod } : { kind: 'file' };
      instances.push({ kind: 'classInstance', name: information.name, className: information.className,
        declaration: command, classNameNode: nameNode, nameNode: value, scope, file: ast });
    }
  }
  const definitions = [...groups.values()].map(group => ({ ...group.definition,
    attributes: group.attributes, methods: group.methods }));
  const methodScopes = new Map<FunctionDefinitionNode | null, { range: AstNode['range']; method: ClassMethod }[]>();
  for (const definition of definitions) {
    for (const method of definition.methods) {
      if (method.body.kind !== 'block') continue;
      const scopes = methodScopes.get(definition.scope) ?? [];
      scopes.push({ method, range: method.body.range });
      methodScopes.set(definition.scope, scopes);
    }
  }
  for (const scopes of methodScopes.values()) scopes.sort((left, right) => left.range.start.offset - right.range.start.offset);
  return { definitions, instances, methodScopes };
}

/** Find method parameter ownership without interpreting class commands again during diagnostics. */
export function classMethodAt(classes: ClassFileHydration, scope: FunctionDefinitionNode | null, offset: number): ClassMethod | null {
  const methods = classes.methodScopes.get(scope) ?? [];
  let low = 0, high = methods.length - 1;
  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const entry = methods[middle];
    if (offset < entry.range.start.offset) high = middle - 1;
    else if (offset >= entry.range.end.offset) low = middle + 1;
    else return entry.method;
  }
  return null;
}
