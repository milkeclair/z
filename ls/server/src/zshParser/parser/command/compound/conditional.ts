import type { IfBranchNode, ListNode } from '../../../ast';
import type { Token } from '../../../lexer';
import type { ParserContext } from '../../context';
import type { NodeResult, ParseState } from '../../state';
import { advanceState, currentToken } from '../../state';
import { endAt, isWord, takeKeyword } from './syntax';
import type { CompoundContents } from './types';
export function readIfBody(
  state: ParseState,
  context: ParserContext,
  open: Token,
): NodeResult<CompoundContents> {
  let current = state;
  let elseBody: ListNode | null = null;

  const collected: IfBranchNode[] = [];

  let keyword = open;

  while (true) {
    const start = context.parseNestedList(current, endAt('then', 'fi'));
    const then = takeKeyword(start.state, 'then');
    const result = context.parseNestedList(then.state, endAt('elif', 'else', 'fi'));
    collected.push({
      kind: 'ifBranch',
      range: { start: keyword.range.start, end: result.node.range.end },
      keyword: keyword.range,
      condition: start.node,
      thenKeyword: then.token?.range ?? null,
      body: result.node,
    });
    current = result.state;
    if (!isWord(currentToken(current), 'elif')) {
      break;
    }
    keyword = currentToken(current);
    current = advanceState(current);
  }

  if (isWord(currentToken(current), 'else')) {
    const result = context.parseNestedList(advanceState(current), endAt('fi'));
    elseBody = result.node;
    current = result.state;
  }
  return { node: { kind: 'ifCommand', branches: collected, elseBody }, state: current };
}
export function readConditionalLoopBody(
  state: ParseState,
  context: ParserContext,
  kind: 'whileCommand' | 'untilCommand',
): NodeResult<CompoundContents> {
  const condition = context.parseNestedList(state, endAt('do', 'done'));
  const doKeyword = takeKeyword(condition.state, 'do');
  const body = context.parseNestedList(doKeyword.state, endAt('done'));
  return { node: { kind, condition: condition.node, body: body.node }, state: body.state };
}
