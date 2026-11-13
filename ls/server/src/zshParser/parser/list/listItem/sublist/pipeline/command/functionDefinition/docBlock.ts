import type { DocBlockNode } from '../../../../../../../ast';
import type { SourceRange, Token } from '../../../../../../../lexer';
import type { CommentContext } from '../../../../../../comment';
import { rangeFromTokens } from '../../../../../../range';

type CommentSearchResult = {
  readonly comment: Token;
  readonly index: number;
};

export function createLeadingDocBlock({
  tokens,
  context,
  targetIndex,
  targetRange,
}: {
  readonly tokens: readonly Token[];
  readonly context: CommentContext;
  readonly targetIndex: number;
  readonly targetRange: SourceRange;
}): DocBlockNode | null {
  const comments = collectLeadingCommentTokens({
    tokens,
    index: targetIndex - 1,
    comments: [],
  });

  if (comments.length === 0) {
    return null;
  } else {
    return {
      kind: 'docBlock',
      range: rangeFromTokens(comments),
      comments: comments.map((token) => {
        const comment = context.byOffset.get(token.range.start.offset);
        if (!comment) throw new Error('Comment context is missing a token');
        return comment;
      }),
      targetRange,
    };
  }
}

function collectLeadingCommentTokens({
  tokens,
  index,
  comments,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly comments: readonly Token[];
}): readonly Token[] {
  const collected = [...comments];
  let cursor = index;
  while (cursor >= 0) {
    const beforeLine = findPreviousNewline({ tokens, index: cursor });
    if (!beforeLine) break;
    const beforeComment = findPreviousComment({ tokens, index: beforeLine.index - 1 });
    if (!beforeComment) break;
    collected.push(beforeComment.comment);
    cursor = beforeComment.index - 1;
  }
  return collected.reverse();
}

function findPreviousNewline({
  tokens,
  index,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
}): { readonly index: number } | null {
  const result = skipBackwardTrivia({
    tokens,
    index,
    allowNewline: false,
  });
  const token = tokens[result.index];

  if (token?.kind === 'newline') {
    return {
      index: result.index,
    };
  } else {
    return null;
  }
}

function skipBackwardTrivia({
  tokens,
  index,
  allowNewline,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly allowNewline: boolean;
}): { readonly index: number } {
  let cursor = index;
  while (tokens[cursor]?.kind === 'whitespace' || tokens[cursor]?.kind === 'continuation' ||
    allowNewline && tokens[cursor]?.kind === 'newline') cursor -= 1;
  return { index: cursor };
}

function findPreviousComment({
  tokens,
  index,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
}): CommentSearchResult | null {
  const result = skipBackwardTrivia({
    tokens,
    index,
    allowNewline: false,
  });
  const token = tokens[result.index];

  if (token?.kind === 'comment' && hasOnlyTriviaBeforeCommentOnLine(tokens, result.index - 1)) {
    return {
      comment: token,
      index: result.index,
    };
  } else {
    return null;
  }
}

function hasOnlyTriviaBeforeCommentOnLine(tokens: readonly Token[], index: number): boolean {
  let cursor = index;
  while (tokens[cursor]?.kind === 'whitespace' || tokens[cursor]?.kind === 'continuation') cursor -= 1;
  return !tokens[cursor] || tokens[cursor].kind === 'newline';
}
