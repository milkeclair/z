import type { WordNode } from '../../zshParser/ast';

const RESERVED_COMMANDS: readonly string[] = [
  'if', 'then', 'else', 'elif', 'fi', 'for', 'select', 'foreach', 'repeat',
  'while', 'until', 'do', 'done', 'case', 'in', 'esac', 'function', 'time',
  'coproc', 'end', '!', '{', '}', 'builtin', 'command', 'exec', 'noglob', 'nocorrect', '-',
];

export function commandInsertion(name: string): string {
  const safe = [...name].every(char =>
    char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' ||
    char >= '0' && char <= '9' || '_.-/'.includes(char));
  if (name && safe && !RESERVED_COMMANDS.includes(name)) return name;
  const escapedQuote = "'" + String.fromCharCode(92) + "''";
  return "'" + name.split("'").join(escapedQuote) + "'";
}

export function namedKey(word: WordNode): string | null {
  const text = word.raw;
  let index = 0;
  while (index < text.length) {
    const char = text[index];
    const valid = char === '_' || char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z' ||
      index > 0 && char >= '0' && char <= '9';
    if (!valid) break;
    index += 1;
  }
  return index > 0 && text[index] === '=' ? text.slice(0, index) : null;
}
