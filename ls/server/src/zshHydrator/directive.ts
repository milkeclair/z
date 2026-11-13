import type { CommentNode } from '../zshParser/ast';
import type { SourceRange } from '../zshParser/lexer';
import { rangeWithinText } from '../zshParser/parser/range';

export type DirectiveArgument = {
  readonly kind: 'directiveArgument'; readonly range: SourceRange; readonly raw: string; readonly value: string;
};
export type Directive = {
  readonly kind: 'directive'; readonly range: SourceRange; readonly raw: string;
  readonly namespace: string; readonly command: string | null; readonly arguments: readonly DirectiveArgument[];
};
export type ControlComment = {
  readonly kind: 'controlComment'; readonly directives: readonly Directive[];
};
export type HydrationOptions = {
  readonly directiveNamespaces?: readonly string[];
};
export function commentPayload(comment: CommentNode): { readonly text: string; readonly start: number } {
  let start = comment.text.startsWith('#') ? 1 : 0;
  while (comment.text[start] === ' ' || comment.text[start] === '\t') start += 1;
  return { text: comment.text.slice(start), start };
}
export function parseDirective(comment: CommentNode, options: HydrationOptions = {}): Directive | null {
  const payload = commentPayload(comment);
  const namespace = (options.directiveNamespaces ?? ['zls']).find((name) => payload.text.startsWith(name + ':'));
  if (!namespace) return null;
  let cursor = payload.start + namespace.length + 1;
  const words: { readonly value: string; readonly start: number; readonly end: number }[] = [];
  while (cursor < comment.text.length) {
    while (comment.text[cursor] === ' ' || comment.text[cursor] === '\t') cursor += 1;
    const start = cursor;
    while (cursor < comment.text.length && comment.text[cursor] !== ' ' && comment.text[cursor] !== '\t') cursor += 1;
    if (cursor > start) words.push({ value: comment.text.slice(start, cursor), start, end: cursor });
  }
  return {
    kind: 'directive', range: rangeWithinText(comment.range, comment.text, payload.start, comment.text.length),
    raw: comment.text.slice(payload.start), namespace, command: words[0]?.value ?? null,
    arguments: words.slice(1).map((word) => ({
      kind: 'directiveArgument', raw: word.value, value: word.value,
      range: rangeWithinText(comment.range, comment.text, word.start, word.end),
    })),
  };
}
