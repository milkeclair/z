import { decodeLiteral } from '../embeddedCode/literal';
import type { ZshFileHydration } from '../zshHydrator';
import type { WordNode, WordPartNode } from '../zshParser/ast';
import type {
  ClassAttribute,
  ClassDefinition,
  ClassFileHydration,
  ClassInstance,
  ClassMethod,
} from '../zshHydrator/classes';
import { ownerAt, type ClassReferenceIssue, type Ownership } from './ownership';
import { parameterAt } from './classContracts';

export type ClassCommandTarget = {
  readonly definition: ClassDefinition;
  // selfは所有クラスを確定できても、呼び出す実体は実行時に決まる。
  readonly instance: ClassInstance | null;
  readonly member: ClassMethod | ClassAttribute;
  readonly operation: 'method' | 'get' | 'set';
};
function staticText(word: WordNode, parts: readonly WordPartNode[]): string | null {
  return parts.reduce<string | null>((text, part) => {
    if (text === null || part.kind !== 'stringLiteral') return null;

    const segment: WordNode = { ...word, range: part.range, raw: part.value, parts: [part] };
    const value = decodeLiteral(segment, true)?.text;
    return value === undefined ? null : text + value;
  }, '');
}

/** 実体IDを展開する変数と、リテラルで書かれたメンバー名を取得する。 */
export function classMemberReference(
  word: WordNode,
): { readonly binding: string; readonly member: string } | null {
  const index = word.parts.findIndex((part) => part.kind !== 'stringLiteral');
  const part = word.parts[index];
  if (!part || staticText(word, word.parts.slice(0, index)) !== '') return null;

  const binding =
    part.kind === 'variableReference'
      ? part.name.value
      : part.kind === 'parameterExpansion'
        ? (/^\$([1-9][0-9]*)$/.exec(part.raw)?.[1] ??
          /^\$\{([A-Za-z_][A-Za-z0-9_]*|[1-9][0-9]*)\}$/.exec(part.raw)?.[1])
        : undefined;
  if (!binding) return null;

  const suffix = staticText(word, word.parts.slice(index + 1));
  return suffix && /^\.[A-Za-z0-9_.]+$/.test(suffix) ? { binding, member: suffix.slice(1) } : null;
}

export function memberTarget(
  definition: ClassDefinition,
  name: string,
  instance: ClassInstance | null,
): ClassCommandTarget | null {
  const method = definition.methods.find((candidate) => candidate.name === name);
  if (method) return { definition, instance, member: method, operation: 'method' };

  const operation = name.endsWith('.get') ? 'get' : name.endsWith('.set') ? 'set' : null;
  if (!operation) return null;

  const attributeName = name.slice(0, -operation.length - 1);
  const attribute = definition.attributes.find((candidate) => candidate.name === attributeName);
  return attribute ? { definition, instance, member: attribute, operation } : null;
}

export function memberRequiresWrite(target: ClassCommandTarget): boolean {
  return (
    target.operation === 'set' ||
    (target.member.kind === 'classMethod' && target.member.access === 'write')
  );
}

/** 呼び出し位置で有効な所有参照と、引数の契約で許可された操作を解決する。 */
export function resolveInstanceCommand(
  file: ZshFileHydration,
  word: WordNode,
  reference: NonNullable<ReturnType<typeof classMemberReference>>,
  files: readonly ClassFileHydration[],
  ownership: Ownership,
):
  | {
      readonly definition: ClassDefinition;
      readonly name: string;
      readonly target: ClassCommandTarget | null;
    }
  | ClassReferenceIssue
  | null {
  const offset = word.range.start.offset;
  const name = '$' + reference.binding + '.' + reference.member;
  const parameter = ownership.typedFunctions
    ? parameterAt(file, reference.binding, offset)?.classReference
    : undefined;
  if (parameter?.access === 'owner') return null;
  const binding = parameter ? null : ownerAt(file, reference.binding, offset, ownership.moves);
  const className = parameter?.className ?? binding?.className;
  if (!className) return null;
  if (binding?.state === 'maybe-uninitialized') {
    return {
      code: 'class-reference-uninitialized',
      message: name + ' may refer to an uninitialized instance.',
    };
  }
  if (binding?.state === 'moved' || binding?.state === 'maybe-moved') {
    return {
      code: 'class-reference-moved',
      message:
        name +
        (binding.state === 'moved'
          ? ' uses a reference whose ownership was moved.'
          : ' uses a reference whose ownership may have moved.'),
    };
  }

  for (let index = files.length - 1; index >= 0; index--) {
    const definition = files[index].definitions.findLast(
      (candidate) => candidate.name === className && candidate.state === 'published',
    );
    if (definition) {
      const target = memberTarget(definition, reference.member, binding?.instance ?? null);
      if (parameter?.access === 'read' && target && memberRequiresWrite(target)) {
        return {
          code: 'class-readonly-write',
          message: name + ' requires write access to the instance.',
        };
      }
      return { definition, name, target };
    }
  }

  return null;
}

/** クラス宣言と実体の束縛が同じノードを参照する間だけ、解決コンテキストを再利用する。 */
export function sameClassFiles(
  left: readonly ClassFileHydration[],
  right: readonly ClassFileHydration[],
): boolean {
  const declarations = (files: readonly ClassFileHydration[]) =>
    files.flatMap((file) => [
      ...file.definitions.map((definition) => definition.declaration),
      ...file.instances.map((instance) => instance.declaration),
    ]);
  const previous = declarations(left);
  const next = declarations(right);

  return previous.length === next.length && previous.every((node, index) => node === next[index]);
}
