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

/** Resolve only published class symbols; targets retain declaration nodes and member provenance. */
export function classCommands(files: readonly ClassFileHydration[]): ClassCommandTargets {
  const definitions = new Map(files.flatMap(file => file.definitions
    .filter(definition => definition.state === 'published')
    .map(definition => [definition.name, definition])));
  const commands = new Map<string, ClassCommandTarget[]>();

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
          const targets = commands.get(name) ?? [];

          targets.push({ definition, member, instance, operation });
          commands.set(name, targets);
        }
      }
    }
  }

  return commands;
}

/** Preserve cached contexts only while all class declaration and binding references are current. */
export function sameClassFiles(left: readonly ClassFileHydration[], right: readonly ClassFileHydration[]): boolean {
  const declarations = (files: readonly ClassFileHydration[]) => files.flatMap(file => [
    ...file.definitions.map(definition => definition.declaration),
    ...file.instances.map(instance => instance.declaration),
  ]);
  const previous = declarations(left);
  const next = declarations(right);

  return previous.length === next.length && previous.every((node, index) => node === next[index]);
}
