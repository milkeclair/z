import type { SimpleCommandNode, WordNode } from '../../zshParser/ast';
import { literalWord } from '../../zshParser/ast/word/literal';
import type { ClassMethodAccess } from './types';

/** 既定権限とインライン本体の位置を、元の引数の単語から取得する。 */
export function methodArguments(command: SimpleCommandNode): {
  readonly access: ClassMethodAccess;
  readonly body: WordNode | null;
} | null {
  let access: ClassMethodAccess = 'read';
  let hasAccess = false;
  let body: WordNode | null = null;
  for (const word of command.arguments.slice(1)) {
    const prefix = word.parts[0];
    const option =
      prefix?.kind === 'stringLiteral' &&
      literalWord({ ...word, raw: prefix.value, parts: [prefix] })?.startsWith('access=');
    if (option) {
      const value = literalWord(word);
      if (hasAccess || (value !== 'access=read' && value !== 'access=write')) return null;
      hasAccess = true;
      access = value === 'access=read' ? 'read' : 'write';
    } else {
      if (body) return null;
      body = word;
    }
  }
  return { access, body };
}
