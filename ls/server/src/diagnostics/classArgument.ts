import type { ZshFileHydration } from '../zshHydrator';
import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { CallScope } from './calls';
import { classArguments, parameterAt } from './classContracts';
import { ownerAt, type ClassReferenceIssue, type Ownership } from './ownership';
import { selfReferenceAt } from './self';

/** 引数コメントの契約を、呼び出し場所で分かるインスタンスと照合する。 */
export function classArgumentIssue({
  command,
  file,
  target,
  ownership,
  scopes,
  isUncertain,
}: {
  readonly command: SimpleCommandNode;
  readonly file: ZshFileHydration;
  readonly target: FunctionDefinitionNode;
  readonly ownership: Ownership;
  readonly scopes: readonly CallScope[];
  readonly isUncertain: (word: WordNode) => boolean;
}): ClassReferenceIssue | null {
  const offset = command.range.start.offset;

  for (const { type, binding, literal, ownerName } of classArguments(
    command,
    target,
    isUncertain,
  )) {
    if (type.access !== 'owner' && literal !== null && !literal.startsWith('z_cls_')) {
      return {
        code: 'class-argument-type',
        message: 'Expected a reference of type ' + type.className + '<' + type.access + '>.',
      };
    }

    if (!binding) {
      continue;
    }

    const parameter =
      binding === 'self'
        ? selfReferenceAt(file, offset, scopes)
        : ownership.typedFunctions
          ? parameterAt(file, binding, offset)?.classReference
          : undefined;
    const owner = parameter ? null : ownerAt(file, binding, offset, ownership.moves);

    if (owner?.state === 'maybe-uninitialized') {
      return {
        code: 'class-reference-uninitialized',
        message: binding + ' may refer to an uninitialized instance.',
      };
    }
    if (owner?.state === 'moved' || owner?.state === 'maybe-moved') {
      return {
        code: 'class-reference-moved',
        message: binding + (owner.state === 'moved' ? ' was moved.' : ' may have moved.'),
      };
    }
    if (type.access === 'owner' && !ownerName && owner) {
      return {
        code: 'class-owner-required',
        message: 'Pass the variable name ' + binding + ' to transfer its ownership.',
      };
    }

    const actual = parameter ?? (owner ? { className: owner.className, access: 'owner' } : null);

    if (!actual) {
      continue;
    }

    if (
      actual.className !== type.className ||
      (type.access === 'owner' && actual.access !== 'owner') ||
      (type.access === 'write' && actual.access === 'read')
    ) {
      return {
        code: 'class-argument-type',
        message: `Expected ${type.className}<${type.access}> for ${binding}, received ${actual.className}<${actual.access}>.`,
      };
    }
  }

  return null;
}
