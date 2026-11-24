import type { ClassReferenceIssue } from './ownership';
import type {
  ClassDefinition,
  ClassFileHydration,
  ClassMethod,
  ZshFileHydration,
} from '../zshHydrator';
import { classMethodAt } from '../zshHydrator';
import type { AstNode, FunctionDefinitionNode, WordNode } from '../zshParser/ast';
import { locate } from '../zshParser/ast';
import type { CallScope } from './calls';
import { memberRequiresWrite, memberTarget, type ClassCommandTarget } from './classes';

function shadowsSelf(path: readonly AstNode[], offset: number, start: number): boolean {
  return path.some(
    (node) =>
      node.kind === 'list' &&
      node.items.some((item) => {
        if (item.sublist.kind !== 'sublist') return false;

        const command = item.sublist.first.first;
        if (
          command.kind !== 'simpleCommand' ||
          command.range.start.offset < start ||
          command.range.start.offset >= offset ||
          command.semantic.role !== 'declaration'
        )
          return false;

        const declaration = command.semantic.declaration;
        if (
          declaration.kind === 'export' ||
          declaration.options.some((option) => option.name.includes('g'))
        ) {
          return false;
        }

        return (
          declaration.names.some((name) => name.value === 'self') ||
          declaration.assignments.some((assignment) => assignment.name.value === 'self')
        );
      }),
  );
}

function methodOwnerAt(
  classes: ClassFileHydration,
  scope: FunctionDefinitionNode | null,
  offset: number,
): {
  readonly definition: ClassDefinition;
  readonly method: ClassMethod;
} | null {
  const block = classMethodAt(classes, scope, offset);

  for (const definition of classes.definitions) {
    if (definition.state !== 'published' || definition.scope !== scope) continue;

    const method = definition.methods.find(
      (candidate) =>
        candidate === block ||
        (candidate.body.kind === 'inline' &&
          candidate.body.value.range.start.offset <= offset &&
          offset < candidate.body.value.range.end.offset),
    );
    if (method) return { definition, method };
  }

  return null;
}

type MethodOwner = { readonly definition: ClassDefinition; readonly method: ClassMethod };

function selfScopeAt(
  file: ZshFileHydration,
  offset: number,
): {
  readonly owner: MethodOwner | null;
  readonly blocked: boolean;
} {
  const location = locate(file.query, offset);
  const path = location?.kind === 'syntax' ? location.path : [];
  const scope =
    path
      .toReversed()
      .find((node): node is FunctionDefinitionNode => node.kind === 'functionDefinition') ?? null;
  const owner = methodOwnerAt(file.classes, scope, offset);
  const body = owner?.method.body;
  const start = body ? (body.kind === 'block' ? body.range : body.value.range).start.offset : 0;
  const shadowed = shadowsSelf(path, offset, start);

  return {
    owner: shadowed ? null : owner,
    blocked: scope !== null || shadowed,
  };
}

/** 文字列のコードも元の所有関係から調べ、通常の関数を越えてselfの所属を推測しない。 */
function owningClass(
  file: ZshFileHydration,
  offset: number,
  scopes: readonly CallScope[],
): MethodOwner | null {
  const current = selfScopeAt(file, offset);
  if (current.owner || current.blocked) return current.owner;

  for (const scope of scopes) {
    const owner = selfScopeAt(scope.file, scope.offset);
    if (owner.owner || owner.blocked) return owner.owner;
  }

  return null;
}

/** メソッドのselfを通常関数へ渡すときも、宣言された権限を保つ。 */
export function selfReferenceAt(
  file: ZshFileHydration,
  offset: number,
  scopes: readonly CallScope[],
) {
  const owner = owningClass(file, offset, scopes);
  return owner ? { className: owner.definition.name, access: owner.method.access } : null;
}

/** 実際の所有メソッドが分かるself参照だけを、共有するメンバー宣言へ結び付ける。 */
export function resolveSelfCommand(
  file: ZshFileHydration,
  word: WordNode,
  name: string,
  scopes: readonly CallScope[],
):
  | {
      readonly definition: ClassDefinition;
      readonly name: string;
      readonly target: ClassCommandTarget | null;
    }
  | ClassReferenceIssue
  | null {
  const owner = owningClass(file, word.range.start.offset, scopes);
  if (!owner) return null;

  const target = memberTarget(owner.definition, name, null);
  const commandName = '$self.' + name;
  if (owner.method.access === 'read' && target && memberRequiresWrite(target)) {
    return {
      code: 'class-readonly-write',
      message: commandName + ' requires write access in a read-only method.',
    };
  }
  return { definition: owner.definition, name: commandName, target };
}
