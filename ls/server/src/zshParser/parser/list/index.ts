import type { ListItemNode, ListNode } from '../../ast';
import { rangeFromTokens } from '../range';
import {
  advanceState,
  currentToken,
  skipTrivia,
  tokenSlice,
} from '../state';
import type { NodeResult, ParseState } from '../state';
import type { ParserContext } from '../context';
import { parseListItem } from './listItem';
import { listTerminatorType } from './listTerminator';
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
      range: rangeFromTokens(tokens, { start: currentToken(result.state).range.start, end: currentToken(result.state).range.start }),
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
  const items: ListItemNode[] = [];
  let current = skipTrivia(state);

  while (!isEnd(currentToken(current))) {
    if (current.stopped) {
      const range = { start: currentToken(current).range.start, end: current.eof.range.end };
      items.push({ kind: 'listItem', range, terminator: null, sublist: { kind: 'unknown', range, reason: 'nestingLimitExceeded' } });
      current = { ...current, index: current.tokens.length - 1 };
      break;
    }
    if (listTerminatorType(currentToken(current))) {
      current = skipTrivia(advanceState(current));
    } else {
      const item = parseListItem({ state: current, context });
      const nextState = item.state.index === current.index && !isEnd(currentToken(item.state))
        ? advanceState(item.state)
        : item.state;

      items.push(item.node);
      current = skipTrivia(nextState);
    }
  }

  return { items, state: current };
}
