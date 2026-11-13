import type { CommentNode } from '../../ast';
import type { Token } from '../../lexer';

export type CommentContext = {
  readonly comments: readonly CommentNode[];
  readonly byOffset: ReadonlyMap<number, CommentNode>;
};

export function mergeComments(previous: CommentContext, comments: readonly CommentNode[]): CommentContext {
  const additions = comments.filter((comment) => !previous.byOffset.has(comment.range.start.offset));
  if (additions.length === 0) return previous;
  const byOffset = new Map(previous.byOffset);
  for (const comment of additions) byOffset.set(comment.range.start.offset, comment);
  return { comments: [...byOffset.values()].sort((a, b) => a.range.start.offset - b.range.start.offset), byOffset };
}
export function createCommentContext(tokens: readonly Token[], previous?: CommentContext): CommentContext {
  const base: CommentContext = previous ?? { comments: [], byOffset: new Map() };
  return mergeComments(base, tokens.filter((token) => token.kind === 'comment').map(createCommentNode));
}
export function createCommentNodes(tokens: readonly Token[]): readonly CommentNode[] {
  return createCommentContext(tokens).comments;
}
export function createCommentNode(token: Token): CommentNode {
  return { kind: 'comment', range: token.range, text: token.value };
}
