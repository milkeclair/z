import type { ClassFileHydration, ClassDefinition, ClassInstance, ClassMethod, ClassAttribute } from '../zshHydrator/classes';

export type ClassCommandTarget = {
  readonly definition: ClassDefinition; readonly instance: ClassInstance;
  readonly member: ClassMethod | ClassAttribute; readonly operation: 'method' | 'get' | 'set';
};
export type ClassCommandTargets = ReadonlyMap<string, readonly ClassCommandTarget[]>;

/** Resolve only published class symbols; targets retain declaration nodes and member provenance. */
export function classCommands(files: readonly ClassFileHydration[]): ClassCommandTargets {
  const definitions = new Map(files.flatMap(file => file.definitions.filter(d => d.state === 'published').map(d => [d.name, d])));
  const commands = new Map<string, ClassCommandTarget[]>();
  for (const file of files) {
    for (const instance of file.instances) {
      const definition = definitions.get(instance.className);
      if (!definition) continue;
      for (const member of [...definition.methods, ...definition.attributes]) {
        const operations: readonly ClassCommandTarget['operation'][] = member.kind === 'classMethod' ? ['method'] : ['get', 'set'];
        for (const operation of operations) {
          const name = instance.name + '.' + member.name + (operation === 'method' ? '' : '.' + operation);
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
  const declarations = (files: readonly ClassFileHydration[]) => files.flatMap(file =>
    [...file.definitions.map(d => d.declaration), ...file.instances.map(i => i.declaration)]);
  const previous = declarations(left), next = declarations(right);
  return previous.length === next.length && previous.every((node, index) => node === next[index]);
}
