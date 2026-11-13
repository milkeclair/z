import { isProcessSubstitutionStart } from '../../../../../../word/composite/token';
import type { SimpleCommandNode, WordNode, AssignNode, RedirectNode } from '../../../../../../../ast';
import type { Token } from '../../../../../../../lexer';
import { isCommandBoundary } from '../../../../../../boundary';
import { rangeFromTokens, enclosingRange } from '../../../../../../range';
import { isRedirectStart, readRedirectNode } from '../../../../../../redirect';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipInlineTrivia,
  skipTrivia,
  tokenSlice,
} from '../../../../../../state';
import type { NodeResult, ParseState } from '../../../../../../state';
import { createSimpleCommandSemantic } from './semantic';
import type { SimpleCommandAccumulator } from './types';
import { readSimpleCommandWord } from './word';

export function parseSimpleCommand(state: ParseState): NodeResult<SimpleCommandNode> {
  const startState = skipTrivia(state);
  const accumulator = readSimpleCommandAccumulator({
    state: startState,
    startIndex: startState.index,
    syntaxEndIndex: startState.index,
    precommandModifiers: [],
    prefixAssignments: [],
    commandName: null,
    arguments: [],
    redirects: [],
  });
  const tokens = tokenSlice(
    accumulator.state,
    accumulator.startIndex,
    accumulator.syntaxEndIndex,
  );

  return {
    node: {
      kind: 'simpleCommand',
      range: enclosingRange(rangeFromTokens(tokens, currentToken(accumulator.state).range), accumulator.redirects),
      precommandModifiers: accumulator.precommandModifiers,
      prefixAssignments: accumulator.prefixAssignments,
      commandName: accumulator.commandName,
      arguments: accumulator.arguments,
      redirects: accumulator.redirects,
      semantic: createSimpleCommandSemantic(accumulator),
    },
    state: accumulator.state,
  };
}

function readSimpleCommandAccumulator(
  accumulator: SimpleCommandAccumulator,
): SimpleCommandAccumulator {
  const args: WordNode[] = [...accumulator.arguments];
  const assignments: AssignNode[] = [...accumulator.prefixAssignments];
  const redirects: RedirectNode[] = [...accumulator.redirects];
  let parts = accumulator;
  while (true) {
    const current = { ...parts, arguments: [], prefixAssignments: [], redirects: [], state: skipInlineTrivia(parts.state) };
    const token = currentToken(current.state);
    if (current.state.stopped || isCommandBoundary(token) || token.kind === 'comment') return { ...current, arguments: args, prefixAssignments: assignments, redirects };
    if (isRedirectStart(current.state)) parts = readRedirect(current);
    else if (token.kind === 'word' || isProcessSubstitutionStart(current.state.tokens, current.state.index)) parts = readSimpleCommandWord(current, token);
    else parts = readUnexpectedToken(current, token);
    args.push(...parts.arguments); assignments.push(...parts.prefixAssignments); redirects.push(...parts.redirects);
  }
}

function readRedirect(parts: SimpleCommandAccumulator): SimpleCommandAccumulator {
  const redirect = readRedirectNode(parts.state);

  return {
    ...parts,
    state: redirect.state,
    syntaxEndIndex: redirect.syntaxEndIndex,
    redirects: [...parts.redirects, redirect.node],
  };
}

function readUnexpectedToken(
  parts: SimpleCommandAccumulator,
  token: Token,
): SimpleCommandAccumulator {
  const diagnosed = addDiagnostic({
    state: parts.state,
    kind: 'unexpectedToken',
    message: `Unexpected token in simple command: ${token.value}`,
    tokens: [token],
  });
  const nextState = advanceState(diagnosed);

  return {
    ...parts,
    state: nextState,
    syntaxEndIndex: nextState.index,
  };
}
