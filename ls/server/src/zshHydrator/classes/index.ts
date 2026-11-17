import { makeMap } from '../../util/collections';
import { again, done, loop } from '../../util/loop';
import type {
  AstNode,
  FileNode,
  FunctionDefinitionNode,
  SimpleCommandNode,
} from '../../zshParser/ast';
import { findAll, mapAst } from '../../zshParser/ast';
import { collectClassInformation } from './collect';
import type {
  ClassFileHydration,
  ClassInformation,
  ClassMethod,
  HydratedClassCommand,
} from './types';
import {
  definitionsFromCommands,
  instancesFromCommands,
  membersFromCommands,
  methodScopesFromDefinitions,
} from './indexes';

export type * from './types';

/** クラスでの役割を示す種別から、付加情報の型を絞り込む。 */
export function isHydratedClassCommand(node: SimpleCommandNode): node is HydratedClassCommand {
  if (!('hydration' in node) || typeof node.hydration !== 'object' || node.hydration === null) {
    return false;
  }

  const information = node.hydration;

  return (
    'kind' in information &&
    'name' in information &&
    typeof information.name === 'string' &&
    (information.kind === 'classDefinition' ||
      information.kind === 'classAttribute' ||
      information.kind === 'classMethod' ||
      information.kind === 'classInstance')
  );
}

/** 汎用の構文ノード型を変えず、クラスの意味情報を取得する。 */
export function classInformationOf(node: SimpleCommandNode): ClassInformation | null {
  return isHydratedClassCommand(node) ? node.hydration : null;
}

/** 通常の構文種別・トークン・範囲を保ったまま、クラスの意味情報を付加する。 */
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
      const { hydration: _hydration, ...syntax } = node;
      return syntax;
    }

    return node;
  });
}

/** 情報の付加後に役割別の索引を組み合わせ、最終ASTの参照だけを保持する。 */
export function classesFromAst(
  ast: FileNode,
  functionDefinitions?: readonly FunctionDefinitionNode[],
): ClassFileHydration {
  const commands = findAll(ast, 'simpleCommand').filter(isHydratedClassCommand);
  if (commands.length === 0) return { definitions: [], instances: [], methodScopes: makeMap() };

  const functions = makeMap(
    (functionDefinitions ?? findAll(ast, 'functionDefinition')).map((node) => [
      node.range.start.offset,
      node,
    ]),
  );
  const members = membersFromCommands(commands);
  const definitions = definitionsFromCommands(ast, commands, functions, members);

  return {
    definitions,
    instances: instancesFromCommands(ast, commands, functions),
    methodScopes: methodScopesFromDefinitions(definitions),
  };
}

/** 診断時にクラスのコマンドを再解釈せず、メソッドの引数の所有関係を調べる。 */
export function classMethodAt(
  classes: ClassFileHydration,
  scope: FunctionDefinitionNode | null,
  offset: number,
): ClassMethod | null {
  const methods = classes.methodScopes.get(scope) ?? [];

  return loop<{ readonly low: number; readonly high: number }, ClassMethod | null>(
    { low: 0, high: methods.length - 1 },
    ({ low, high }) => {
      if (low > high) return done(null);

      const middle = Math.floor((low + high) / 2);
      const entry = methods[middle];

      if (offset < entry.range.start.offset) {
        return again({ low, high: middle - 1 });
      }

      return offset >= entry.range.end.offset
        ? again({ low: middle + 1, high })
        : done(entry.method);
    },
  );
}
