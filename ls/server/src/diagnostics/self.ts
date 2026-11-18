import { decodeLiteral } from '../embeddedCode/literal';
import type { ClassDefinition, ZshFileHydration } from '../zshHydrator';
import { classMethodAt } from '../zshHydrator';
import type { AstNode, FunctionDefinitionNode, WordNode, WordPartNode } from '../zshParser/ast';
import { locate } from '../zshParser/ast';
import type { CallScope } from './calls';
import type { ClassCommandTarget } from './classes';

function staticText(word: WordNode, parts: readonly WordPartNode[]): string | null {
  return parts.reduce<string | null>((text, part) => {
    if (text === null || part.kind !== 'stringLiteral') return null;

    const segment: WordNode = { ...word, range: part.range, raw: part.value, parts: [part] };
    const value = decodeLiteral(segment, true)?.text;
    return value === undefined ? null : text + value;
  }, '');
}

function selfMemberName(word: WordNode): string | null {
  const index = word.parts.findIndex(
    (part) =>
      (part.kind === 'variableReference' && part.name.value === 'self') ||
      (part.kind === 'parameterExpansion' && part.raw === '${self}'),
  );
  if (index < 0 || staticText(word, word.parts.slice(0, index)) !== '') return null;

  const suffix = staticText(word, word.parts.slice(index + 1));
  if (!suffix?.startsWith('.') || suffix.length === 1) return null;

  const staticName = [...suffix].every(
    (char) =>
      char === '.' ||
      char === '_' ||
      (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9'),
  );
  return staticName ? suffix.slice(1) : null;
}

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

function ownerAt(
  file: ZshFileHydration,
  offset: number,
): {
  readonly definition: ClassDefinition | null;
  readonly blocked: boolean;
} {
  const location = locate(file.query, offset);
  const scope =
    location?.kind === 'syntax'
      ? (location.path
          .toReversed()
          .find((node): node is FunctionDefinitionNode => node.kind === 'functionDefinition') ??
        null)
      : null;
  const block = classMethodAt(file.classes, scope, offset);
  const definition = file.classes.definitions.find(
    (candidate) =>
      candidate.state === 'published' &&
      candidate.scope === scope &&
      candidate.methods.some(
        (method) =>
          method === block ||
          (method.body.kind === 'inline' &&
            method.body.value.range.start.offset <= offset &&
            offset < method.body.value.range.end.offset),
      ),
  );

  const method = definition?.methods.find(
    (candidate) =>
      candidate === block ||
      (candidate.body.kind === 'inline' &&
        candidate.body.value.range.start.offset <= offset &&
        offset < candidate.body.value.range.end.offset),
  );
  const start = method
    ? method.body.kind === 'block'
      ? method.body.range.start.offset
      : method.body.value.range.start.offset
    : 0;
  const shadowed = location?.kind === 'syntax' && shadowsSelf(location.path, offset, start);

  return {
    definition: shadowed ? null : (definition ?? null),
    blocked: scope !== null || shadowed,
  };
}

/** 文字列のコードも元の所有関係から調べ、通常の関数を越えてselfの所属を推測しない。 */
function owningClass(
  file: ZshFileHydration,
  word: WordNode,
  scopes: readonly CallScope[],
): ClassDefinition | null {
  const current = ownerAt(file, word.range.start.offset);
  if (current.definition || current.blocked) return current.definition;

  for (const scope of scopes) {
    const owner = ownerAt(scope.file, scope.offset);
    if (owner.definition || owner.blocked) return owner.definition;
  }

  return null;
}

function memberTarget(definition: ClassDefinition, name: string): ClassCommandTarget | null {
  const method = definition.methods.find((candidate) => candidate.name === name);
  if (method) return { definition, instance: null, member: method, operation: 'method' };

  const operation = name.endsWith('.get') ? 'get' : name.endsWith('.set') ? 'set' : null;
  if (!operation) return null;

  const attributeName = name.slice(0, -operation.length - 1);
  const attribute = definition.attributes.find((candidate) => candidate.name === attributeName);
  return attribute ? { definition, instance: null, member: attribute, operation } : null;
}

/** 実際の所有メソッドが分かるself参照だけを、共有するメンバー宣言へ結び付ける。 */
export function resolveSelfCommand(
  file: ZshFileHydration,
  word: WordNode,
  scopes: readonly CallScope[],
): {
  readonly definition: ClassDefinition;
  readonly name: string;
  readonly target: ClassCommandTarget | null;
} | null {
  const name = selfMemberName(word);
  if (!name) return null;

  const definition = owningClass(file, word, scopes);
  return definition
    ? { definition, name: '$self.' + name, target: memberTarget(definition, name) }
    : null;
}
