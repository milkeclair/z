import type { SimpleCommandNode } from '../zshParser/ast';
import { literalWord } from '../refreshFunctions/word';

const BUILTINS: ReadonlyMap<string, readonly string[]> = new Map([
  ['zsh/datetime', ['strftime']],
  ['zsh/net/tcp', ['ztcp']],
  ['zsh/system', ['syserror', 'sysopen', 'sysread', 'sysseek', 'syswrite', 'zsystem']],
  ['zsh/zpty', ['zpty']],
  ['zsh/zselect', ['zselect']],
]);

export function moduleBuiltins(command: SimpleCommandNode): readonly string[] {
  if (command.precommandModifiers.some(modifier => modifier.type === 'command' &&
    modifier.options.some(option => option.name.includes('v') || option.name.includes('V')))) return [];
  const values: string[] = [];
  for (const word of command.arguments) {
    const value = literalWord(word);
    if (value === null) return [];
    values.push(value);
  }
  const options = new Set<string>();
  let index = 0;
  while (values[index]?.startsWith('-')) {
    const option = values[index++];
    if (option === '--') break;
    for (const flag of option.slice(1)) options.add(flag);
  }
  const modules = values.slice(index);
  if (!modules.length) return [];
  if (options.has('F')) {
    if ([...options].some(flag => !'Fa'.includes(flag))) return [];
    const builtins = new Set<string>();
    for (const feature of modules.slice(1)) {
      if (feature.startsWith('b:')) builtins.add(feature.slice(2));
      else if (feature.startsWith('+b:')) builtins.add(feature.slice(3));
      else if (feature.startsWith('-b:')) builtins.delete(feature.slice(3));
    }
    return [...builtins];
  }
  if (options.has('a')) {
    if ([...options].some(flag => !'abi'.includes(flag))) return [];
    return modules.length > 1 ? modules.slice(1) : modules;
  }
  if ([...options].some(flag => !'is'.includes(flag))) return [];
  return modules.flatMap(module => BUILTINS.get(module) ?? []);
}
