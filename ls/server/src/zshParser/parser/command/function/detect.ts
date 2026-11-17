import { again, done, loop } from '../../../../util/loop';
import type { Token } from '../../../lexer';
import type { ParseState } from '../../state';
import { currentToken } from '../../state';
import { isAssignmentPrefix } from '../../word';

const FunctionKeyword = 'function';

export function isFunctionDefinitionStart(state: ParseState): boolean {
  const token = currentToken(state);

  if (isFunctionKeyword(token)) {
    return true;
  } else {
    return shCompatibleHeaderEndIndex(state.tokens, state.index) !== null;
  }
}

export function isFunctionKeyword(token: Token): boolean {
  return token.kind === 'word' && !token.quoted && token.value === FunctionKeyword;
}

function shCompatibleHeaderEndIndex(tokens: readonly Token[], startIndex: number): number | null {
  const names = readNamePreview({
    tokens,
    index: startIndex,
    count: 0,
  });

  if (names.count === 0) {
    return null;
  } else {
    const openIndex = nextInlineSyntaxIndex(tokens, names.index);
    const openParen = tokens[openIndex];

    if (openParen?.operatorKind !== 'leftParen') {
      return null;
    } else {
      const closeIndex = nextInlineSyntaxIndex(tokens, openIndex + 1);
      const closeParen = tokens[closeIndex];

      if (closeParen?.operatorKind === 'rightParen') {
        return closeIndex;
      } else {
        return null;
      }
    }
  }
}

function readNamePreview({
  tokens,
  index,
  count,
}: {
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly count: number;
}): {
  readonly count: number;
  readonly index: number;
} {
  const initial = { index: nextInlineSyntaxIndex(tokens, index), count };

  return loop(initial, (current) => {
    const token = tokens[current.index];

    return token && isFunctionNameCandidate(token)
      ? again({ index: nextInlineSyntaxIndex(tokens, current.index + 1), count: current.count + 1 })
      : done(current);
  });
}

function isFunctionNameCandidate(token: Token): boolean {
  return token.kind === 'word' && !isFunctionKeyword(token) && !isAssignmentPrefix(token.value);
}

function nextInlineSyntaxIndex(tokens: readonly Token[], index: number): number {
  return loop(index, (cursor) =>
    tokens[cursor]?.kind === 'whitespace' || tokens[cursor]?.kind === 'continuation'
      ? again(cursor + 1)
      : done(cursor),
  );
}
