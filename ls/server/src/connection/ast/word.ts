import type { SimpleCommandNode } from '../../zshParser/ast';
import { literalWord } from '../../zshParser/ast/word/literal';

export { namedKey } from '../../zshParser/ast/word/literal';

const RESERVED_COMMANDS: readonly string[] = [
  'if',
  'then',
  'else',
  'elif',
  'fi',
  'for',
  'select',
  'foreach',
  'repeat',
  'while',
  'until',
  'do',
  'done',
  'case',
  'in',
  'esac',
  'function',
  'time',
  'coproc',
  'end',
  '!',
  '{',
  '}',
  'builtin',
  'command',
  'exec',
  'noglob',
  'nocorrect',
  '-',
];

export function commandInsertion(name: string): string {
  const safe = [...name].every(
    (char) =>
      (char >= 'a' && char <= 'z') ||
      (char >= 'A' && char <= 'Z') ||
      (char >= '0' && char <= '9') ||
      '_.-/'.includes(char),
  );

  if (name && safe && !RESERVED_COMMANDS.includes(name)) {
    return name;
  }

  const escapedQuote = "'" + String.fromCharCode(92) + "''";

  return "'" + name.split("'").join(escapedQuote) + "'";
}

/** z.arg.named が参照する静的な引数名を取得する。 */
export function zArgNamedKey(command: SimpleCommandNode): string | null {
  const argument = command.arguments[0];

  return argument && command.commandName && literalWord(command.commandName.word) === 'z.arg.named'
    ? literalWord(argument)
    : null;
}
