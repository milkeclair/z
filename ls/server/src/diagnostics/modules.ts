import { addValue, deleteValue, makeSet, unionValues } from '../util/collections';
import { literalWord } from '../refreshFunctions/word';
import { again, done, loop } from '../util/loop';
import type { SimpleCommandNode } from '../zshParser/ast';

const BUILTINS: ReadonlyMap<string, readonly string[]> = new Map([
  ['zsh/datetime', ['strftime']],
  ['zsh/net/tcp', ['ztcp']],
  ['zsh/system', ['syserror', 'sysopen', 'sysread', 'sysseek', 'syswrite', 'zsystem']],
  ['zsh/zpty', ['zpty']],
  ['zsh/zselect', ['zselect']],
]);

export function moduleBuiltins(command: SimpleCommandNode): readonly string[] {
  if (
    command.precommandModifiers.some(
      (modifier) =>
        modifier.type === 'command' &&
        modifier.options.some((option) => option.name.includes('v') || option.name.includes('V')),
    )
  ) {
    return [];
  }

  const values = command.arguments.map((word) => literalWord(word));

  if (!values.every((value): value is string => value !== null)) {
    return [];
  }

  const initial = { index: 0, options: makeSet<string>() };
  const parsed = loop<typeof initial, typeof initial>(initial, (state) => {
    const option = values[state.index];

    if (!option?.startsWith('-')) {
      return done(state);
    }

    return option === '--'
      ? done({ ...state, index: state.index + 1 })
      : again({ index: state.index + 1, options: unionValues(state.options, option.slice(1)) });
  });
  const { index, options } = parsed;
  const modules = values.slice(index);

  if (!modules.length) {
    return [];
  }

  if (options.has('F')) {
    if ([...options].some((flag) => !'Fa'.includes(flag))) {
      return [];
    }

    const builtins = modules.slice(1).reduce((previous, feature) => {
      if (feature.startsWith('b:')) {
        return addValue(previous, feature.slice(2));
      }

      if (feature.startsWith('+b:')) {
        return addValue(previous, feature.slice(3));
      }

      return feature.startsWith('-b:') ? deleteValue(previous, feature.slice(3)) : previous;
    }, makeSet<string>());

    return [...builtins];
  }

  if (options.has('a')) {
    if ([...options].some((flag) => !'abi'.includes(flag))) {
      return [];
    }

    return modules.length > 1 ? modules.slice(1) : modules;
  }

  if ([...options].some((flag) => !'is'.includes(flag))) {
    return [];
  }

  return modules.flatMap((module) => BUILTINS.get(module) ?? []);
}
