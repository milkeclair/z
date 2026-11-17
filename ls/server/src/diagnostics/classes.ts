import { castDraft } from 'immer';
import { makeMap, produce } from '../util/collections';
import type {
  ClassAttribute,
  ClassDefinition,
  ClassFileHydration,
  ClassInstance,
  ClassMethod,
} from '../zshHydrator/classes';

export type ClassCommandTarget = {
  readonly definition: ClassDefinition;
  readonly instance: ClassInstance;
  readonly member: ClassMethod | ClassAttribute;
  readonly operation: 'method' | 'get' | 'set';
};
export type ClassCommandTargets = ReadonlyMap<string, readonly ClassCommandTarget[]>;

/** 公開済みクラスだけを解決し、宣言ノードとメンバーの定義元を参照先に保持する。 */
export function classCommands(files: readonly ClassFileHydration[]): ClassCommandTargets {
  const definitions = makeMap(
    files.flatMap((file) =>
      file.definitions
        .filter((definition) => definition.state === 'published')
        .map((definition) => [definition.name, definition]),
    ),
  );
  return produce(makeMap<string, readonly ClassCommandTarget[]>(), (draft) => {
    for (const file of files) {
      for (const instance of file.instances) {
        const definition = definitions.get(instance.className);
        if (!definition) continue;

        for (const member of [...definition.methods, ...definition.attributes]) {
          const operations: readonly ClassCommandTarget['operation'][] =
            member.kind === 'classMethod' ? ['method'] : ['get', 'set'];

          for (const operation of operations) {
            const suffix = operation === 'method' ? '' : '.' + operation;
            const name = instance.name + '.' + member.name + suffix;
            const targets = draft.get(name) ?? [];

            targets.push(castDraft({ definition, member, instance, operation }));
            draft.set(name, targets);
          }
        }
      }
    }
  });
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
