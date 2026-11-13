import type { ListItemNode } from '../../../ast';
import { rangeFromTokens, enclosingRange } from '../../range';
import { skipTrivia, tokenSlice } from '../../state';
import type { NodeResult, ParseState } from '../../state';
import type { ParserContext } from '../../context';
import { parseSublist } from './sublist';
import { readListTerminator } from './terminator';

export function parseListItem({
  state,
  context,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
}): NodeResult<ListItemNode> {
  const startIndex = state.index;
  const sublist = parseSublist({
    state,
    context,
  });
  const terminator = readListTerminator(skipTrivia(sublist.state));
  const tokens = tokenSlice(terminator.state, startIndex, terminator.state.index);

  return {
    node: {
      kind: 'listItem',
      range: enclosingRange(rangeFromTokens(tokens, sublist.node.range), [sublist.node]),
      sublist: sublist.node,
      terminator: terminator.node,
    },
    state: terminator.state,
  };
}
