import type { CommentNode } from '../../ast';
import type { Token } from '../../lexer';

export type CommentContext = {
  readonly comments: readonly CommentNode[];
  readonly byOffset: ReadonlyMap<number, CommentNode>;
};

export function mergeComments(
  previous: CommentContext,
  comments: readonly CommentNode[],
): CommentContext {
  const additions = comments.filter(
    (comment) => !previous.byOffset.has(comment.range.start.offset),
  );

  if (additions.length === 0) {
    return previous;
  }

  const entries = additions.map((comment): readonly [number, CommentNode] => [
    comment.range.start.offset,
    comment,
  ]);
  const byOffset = new Map([...previous.byOffset, ...entries]);

  return {
    comments: [...byOffset.values()].toSorted(
      (left, right) => left.range.start.offset - right.range.start.offset,
    ),
    byOffset,
  };
}

export function createCommentContext(
  tokens: readonly Token[],
  previous?: CommentContext,
): CommentContext {
  const base: CommentContext = previous ?? { comments: [], byOffset: new Map() };

  return mergeComments(
    base,
    tokens.filter((token) => token.kind === 'comment').map(createCommentNode),
  );
}

export function createCommentNodes(tokens: readonly Token[]): readonly CommentNode[] {
  return createCommentContext(tokens).comments;
}

export function createCommentNode(token: Token): CommentNode {
  return { kind: 'comment', range: token.range, text: token.value };
}
