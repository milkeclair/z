import { again, done, loop } from '../../../util/loop';
import { pushStack, stackValues, type Stack } from '../../../util/stack';
import type { ListItemNode, ListNode } from '../../ast';
import type { ParserContext } from '../context';
import { parseListItem } from '../listItem';
import { rangeFromTokens } from '../range';
import type { NodeResult, ParseState } from '../state';
import { advanceState, currentToken, skipTrivia, tokenSlice } from '../state';
import { listTerminatorType } from './terminator';
import type { ListEnd } from './types';

type ListItemsResult = {
  readonly items: readonly ListItemNode[];
  readonly state: ParseState;
};

export function parseList(state: ParseState, isEnd: ListEnd): NodeResult<ListNode> {
  const context: ParserContext = {
    parseNestedList: (nestedState, nestedEnd) =>
      parseListWithContext(nestedState, nestedEnd, context),
  };

  return parseListWithContext(state, isEnd, context);
}

function parseListWithContext(
  state: ParseState,
  isEnd: ListEnd,
  context: ParserContext,
): NodeResult<ListNode> {
  const startIndex = state.index;
  const result = parseListItems({
    state,
    context,
    isEnd,
  });
  const tokens = tokenSlice(result.state, startIndex, result.state.index);

  return {
    node: {
      kind: 'list',
      range: rangeFromTokens(tokens, {
        start: currentToken(result.state).range.start,
        end: currentToken(result.state).range.start,
      }),
      items: result.items,
    },
    state: result.state,
  };
}

function parseListItems({
  state,
  context,
  isEnd,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly isEnd: ListEnd;
}): ListItemsResult {
  type Progress = {
    readonly state: ParseState;
    readonly items: Stack<ListItemNode> | null;
  };

  const result = loop<Progress, Progress>({ state: skipTrivia(state), items: null }, (progress) => {
    const { state: current, items } = progress;
    const token = currentToken(current);

    if (isEnd(token)) {
      return done(progress);
    }

    if (current.stopped) {
      const range = { start: token.range.start, end: current.eof.range.end };
      const item: ListItemNode = {
        kind: 'listItem',
        range,
        terminator: null,
        sublist: { kind: 'unknown', range, reason: 'nestingLimitExceeded' },
      };

      return done({
        items: pushStack(item, items),
        state: { ...current, index: current.tokens.length - 1 },
      });
    }

    if (listTerminatorType(token)) {
      return again({ state: skipTrivia(advanceState(current)), items });
    }

    const item = parseListItem({ state: current, context });
    const next =
      item.state.index === current.index && !isEnd(currentToken(item.state))
        ? advanceState(item.state)
        : item.state;

    return again({ state: skipTrivia(next), items: pushStack(item.node, items) });
  });

  return { items: Array.from(stackValues(result.items)).toReversed(), state: result.state };
}
