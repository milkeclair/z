import * as Immutable from 'immutable';
import { again, done, loop } from '../../../../util/loop';
import type { IfBranchNode } from '../../../ast';
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
  const initial = { current: state, keyword: open, branches: Immutable.List<IfBranchNode>() };
  const parsed = loop<typeof initial, typeof initial>(initial, (progress) => {
    const condition = context.parseNestedList(progress.current, endAt('then', 'fi'));
    const then = takeKeyword(condition.state, 'then');
    const body = context.parseNestedList(then.state, endAt('elif', 'else', 'fi'));
    const branches = progress.branches.push({
      kind: 'ifBranch',
      range: { start: progress.keyword.range.start, end: body.node.range.end },
      keyword: progress.keyword.range,
      condition: condition.node,
      thenKeyword: then.token?.range ?? null,
      body: body.node,
    });
    const keyword = currentToken(body.state);

    return isWord(keyword, 'elif')
      ? again({ current: advanceState(body.state), keyword, branches })
      : done({ current: body.state, keyword: progress.keyword, branches });
  });
  const alternative = isWord(currentToken(parsed.current), 'else')
    ? context.parseNestedList(advanceState(parsed.current), endAt('fi'))
    : null;

  return {
    node: {
      kind: 'ifCommand',
      branches: parsed.branches.toArray(),
      elseBody: alternative?.node ?? null,
    },
    state: alternative?.state ?? parsed.current,
  };
}

export function readConditionalLoopBody(
  state: ParseState,
  context: ParserContext,
  kind: 'whileCommand' | 'untilCommand',
): NodeResult<CompoundContents> {
  const condition = context.parseNestedList(state, endAt('do', 'done'));
  const keyword = takeKeyword(condition.state, 'do');
  const body = context.parseNestedList(keyword.state, endAt('done'));

  return { node: { kind, condition: condition.node, body: body.node }, state: body.state };
}
