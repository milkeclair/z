import { List } from 'immutable';
import { again, done, loop } from '../util/loop';
import { horizontalWhitespaceEnd, textWhileEnd } from '../util/text';
import type { CommentNode } from '../zshParser/ast';
import type { SourceRange } from '../zshParser/lexer';
import { rangeWithinText } from '../zshParser/parser/range';

export type DirectiveArgument = {
  readonly kind: 'directiveArgument';
  readonly range: SourceRange;
  readonly raw: string;
  readonly value: string;
};
export type Directive = {
  readonly kind: 'directive';
  readonly range: SourceRange;
  readonly raw: string;
  readonly namespace: string;
  readonly command: string | null;
  readonly arguments: readonly DirectiveArgument[];
};
export type ControlComment = {
  readonly kind: 'controlComment';
  readonly directives: readonly Directive[];
};
export type HydrationOptions = {
  readonly directiveNamespaces?: readonly string[];
};
export function commentPayload(comment: CommentNode): {
  readonly text: string;
  readonly start: number;
} {
  const start = horizontalWhitespaceEnd(comment.text, comment.text.startsWith('#') ? 1 : 0);
  return { text: comment.text.slice(start), start };
}
export function parseDirective(
  comment: CommentNode,
  options: HydrationOptions = {},
): Directive | null {
  const payload = commentPayload(comment);
  const namespace = (options.directiveNamespaces ?? ['zls']).find((name) =>
    payload.text.startsWith(name + ':'),
  );
  if (!namespace) {
    return null;
  }
  type Word = { readonly value: string; readonly start: number; readonly end: number };
  const words = loop<{ readonly index: number; readonly words: List<Word> }, List<Word>>(
    { index: payload.start + namespace.length + 1, words: List() },
    (progress) => {
      const start = horizontalWhitespaceEnd(comment.text, progress.index);
      if (start >= comment.text.length) {
        return done(progress.words);
      }
      const end = textWhileEnd(comment.text, start, (char) => char !== ' ' && char !== '\t');
      return again({
        index: end,
        words: progress.words.push({ value: comment.text.slice(start, end), start, end }),
      });
    },
  );
  return {
    kind: 'directive',
    range: rangeWithinText(comment.range, comment.text, payload.start, comment.text.length),
    raw: comment.text.slice(payload.start),
    namespace,
    command: words.first()?.value ?? null,
    arguments: words
      .skip(1)
      .map(
        (word): DirectiveArgument => ({
          kind: 'directiveArgument',
          raw: word.value,
          value: word.value,
          range: rangeWithinText(comment.range, comment.text, word.start, word.end),
        }),
      )
      .toArray(),
  };
}
