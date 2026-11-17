import fs from 'node:fs';
import path from 'node:path';
import type { SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { ShellEnvironment } from './environment';
import type { Declarations } from './facts';

export type ResolutionContext = Declarations & {
  readonly environment: ShellEnvironment;
  readonly projectRoot: string;
};

export function isAliasReference(
  name: string,
  word: WordNode,
  context: ResolutionContext,
): boolean {
  if (word.quoted || word.raw !== name) {
    return false;
  }

  const environment = context.environment;
  const suffix = name.slice(name.lastIndexOf('.') + 1);

  return (
    context.aliases.has(name) ||
    context.globalAliases.has(name) ||
    (name.includes('.') && context.suffixAliases.has(suffix)) ||
    (environment.kind === 'available' &&
      (environment.aliases.has(name) ||
        environment.globalAliases.has(name) ||
        (name.includes('.') && environment.suffixAliases.has(suffix))))
  );
}

function isExecutablePath(name: string, context: ResolutionContext): boolean | null {
  if (!name.includes('/')) {
    return null;
  }

  const filename = path.isAbsolute(name)
    ? name
    : context.projectRoot
      ? path.resolve(context.projectRoot, name)
      : null;

  if (!filename) {
    return null;
  }

  try {
    if (!fs.statSync(filename).isFile()) {
      return path.isAbsolute(name) ? false : null;
    }

    fs.accessSync(filename, fs.constants.X_OK);

    return true;
  } catch {
    return path.isAbsolute(name) ? false : null;
  }
}

export function isKnownShellCommand(
  name: string,
  command: SimpleCommandNode,
  context: ResolutionContext,
): boolean | null {
  const environment = context.environment;

  if (environment.kind !== 'available') {
    return null;
  }

  const builtin = command.precommandModifiers.some((modifier) => modifier.type === 'builtin');
  const knownBuiltin = environment.builtins.has(name) || context.builtins.has(name);

  if (builtin) {
    return knownBuiltin;
  }

  const commandOnly = command.precommandModifiers.some((modifier) => modifier.type === 'command');

  if (
    command.precommandModifiers.some(
      (modifier) =>
        modifier.type === 'command' && modifier.options.some((option) => option.name.includes('p')),
    )
  ) {
    return null;
  }

  if (!commandOnly && environment.functions.has(name)) {
    return true;
  }

  if (name.includes('/')) {
    return isExecutablePath(name, context);
  }

  return (
    environment.commands.has(name) ||
    ((!commandOnly || environment.commandBuiltins) && knownBuiltin) ||
    (!commandOnly && (environment.functions.has(name) || context.autoloads.has(name)))
  );
}
