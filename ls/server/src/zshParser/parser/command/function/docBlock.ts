import { appendItems, collectArray } from '../../../../util/collections';
import { again, done, loop } from '../../../../util/loop';
import type { DocBlockNode } from '../../../ast';
import type { SourceRange, Token } from '../../../lexer';
import type { CommentContext } from '../../comment';
import { rangeFromTokens } from '../../range';

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

        if (!comment) {
          throw new Error('Comment context is missing a token');
        }

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
  const initial = { index, comments: collectArray(comments) };

  return loop<typeof initial, readonly Token[]>(initial, (current) => {
    if (current.index < 0) {
      return done(current.comments.toReversed());
    }

    const beforeLine = findPreviousNewline({ tokens, index: current.index });
    const beforeComment =
      beforeLine && findPreviousComment({ tokens, index: beforeLine.index - 1 });

    return beforeComment
      ? again({
          index: beforeComment.index - 1,
          comments: appendItems(current.comments, beforeComment.comment),
        })
      : done(current.comments.toReversed());
  });
}

function findPreviousNewline({
  tokens,
  index,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
}): {
  readonly index: number;
} | null {
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
}): {
  readonly index: number;
} {
  const cursor = loop(index, (current) =>
    tokens[current]?.kind === 'whitespace' ||
    tokens[current]?.kind === 'continuation' ||
    (allowNewline && tokens[current]?.kind === 'newline')
      ? again(current - 1)
      : done(current),
  );

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
  const cursor = skipBackwardTrivia({ tokens, index, allowNewline: false }).index;

  return !tokens[cursor] || tokens[cursor].kind === 'newline';
}
