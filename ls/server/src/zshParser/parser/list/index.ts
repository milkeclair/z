import { List } from 'immutable';
import { loop, again, done } from '../../../util/loop';
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
  const initial = { current: skipTrivia(state), items: List<ListItemNode>() };
  return loop<typeof initial, ListItemsResult>(initial, ({ current, items }) => {
    if (isEnd(currentToken(current))) {
      return done({ items: items.toArray(), state: current });
    }
    if (current.stopped) {
      const range = { start: currentToken(current).range.start, end: current.eof.range.end };
      return done({
        items: items
          .push({
            kind: 'listItem',
            range,
            terminator: null,
            sublist: { kind: 'unknown', range, reason: 'nestingLimitExceeded' },
          })
          .toArray(),
        state: { ...current, index: current.tokens.length - 1 },
      });
    }
    if (listTerminatorType(currentToken(current))) {
      return again({ current: skipTrivia(advanceState(current)), items });
    }
    const item = parseListItem({ state: current, context });
    const next =
      item.state.index === current.index && !isEnd(currentToken(item.state))
        ? advanceState(item.state)
        : item.state;
    return again({ current: skipTrivia(next), items: items.push(item.node) });
  });
}
