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

/** 本体や値をコピーせず、最終AST内のメンバーの構文ノードを保持する。 */
function memberFromCommand(command: HydratedClassCommand): LocatedMember | null {
  const information = command.hydration;
  const [nameNode, value] = command.arguments;
  if (!nameNode) return null;

  const base = { name: information.name, declaration: command, nameNode };
  switch (information.kind) {
    case 'classAttribute':
      if (!value) return null;

      return {
        classOffset: information.classOffset,
        member: { ...base, kind: 'classAttribute', defaultValue: value },
      };
    case 'classMethod':
      if (information.body.kind === 'inline') {
        if (!value) return null;

        return {
          classOffset: information.classOffset,
          member: { ...base, kind: 'classMethod', body: { kind: 'inline', value } },
        };
      }

      return {
        classOffset: information.classOffset,
        member: { ...base, kind: 'classMethod', body: information.body },
      };
    default:
      return null;
  }
}

/** 入力コマンドと既存の索引を変えず、新しいメンバーの組を構築する。 */
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

/** 定義を、最終ASTの所有関数と新しく構築したメンバーの組へ対応付ける。 */
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

/** 未完了と破棄済みの状態も含め、構文の順序で定義を集める。 */
export function definitionsFromCommands(ast: FileNode, commands: readonly HydratedClassCommand[],
  functions: ReadonlyMap<number, FunctionDefinitionNode>,
  members: ReadonlyMap<number, MemberGroup>): readonly ClassDefinition[] {
  return commands.map(command => definitionFromCommand(ast, command, functions, members))
    .filter((definition): definition is ClassDefinition => definition !== null);
}

/** 情報を付加した最終構文ノードだけを使い、構文スコープの所有関係を解決する。 */
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

/** 実体のクラス名・変数名の単語を、最終ASTの所有スコープに対応付ける。 */
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

/** コマンドや他のファイルの索引を変えず、実体の束縛を集める。 */
export function instancesFromCommands(ast: FileNode, commands: readonly HydratedClassCommand[],
  functions: ReadonlyMap<number, FunctionDefinitionNode>): readonly ClassInstance[] {
  const commandByOffset = new Map(commands.map(node => [node.range.start.offset, node]));

  return commands.map(command => instanceFromCommand(ast, command, functions, commandByOffset))
    .filter((instance): instance is ClassInstance => instance !== null);
}

/** 宣言を再解釈せずに引数の所有関係を判定できるよう、本体の範囲を索引化する。 */
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
