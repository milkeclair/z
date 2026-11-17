import { collectArray } from '../../../../util/collections';
import { again, done, loop } from '../../../../util/loop';
import type { SimpleCommandNode } from '../../../ast';
import type { Token } from '../../../lexer';
import { isCommandBoundary } from '../../boundary';
import { enclosingRange, rangeFromTokens } from '../../range';
import { isRedirectStart, readRedirectNode } from '../../redirect';
import type { NodeResult, ParseState } from '../../state';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipInlineTrivia,
  skipTrivia,
  tokenSlice,
} from '../../state';
import { isParenthesizedWordStart, isProcessSubstitutionStart } from '../../word/composite/token';
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
  const tokens = tokenSlice(accumulator.state, accumulator.startIndex, accumulator.syntaxEndIndex);

  return {
    node: {
      kind: 'simpleCommand',
      range: enclosingRange(
        rangeFromTokens(tokens, currentToken(accumulator.state).range),
        accumulator.redirects,
      ),
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
  const initial = {
    parts: accumulator,
    args: collectArray(accumulator.arguments),
    assignments: collectArray(accumulator.prefixAssignments),
    redirects: collectArray(accumulator.redirects),
  };

  return loop<typeof initial, SimpleCommandAccumulator>(initial, (progress) => {
    const current = {
      ...progress.parts,
      arguments: [],
      prefixAssignments: [],
      redirects: [],
      state: skipInlineTrivia(progress.parts.state),
    };
    const token = currentToken(current.state);

    if (current.state.stopped || isCommandBoundary(token) || token.kind === 'comment') {
      return done({
        ...current,
        arguments: progress.args,
        prefixAssignments: progress.assignments,
        redirects: progress.redirects,
      });
    }

    const parts = readNextCommandPart(current, token);

    return again({
      parts,
      args: progress.args.concat(parts.arguments),
      assignments: progress.assignments.concat(parts.prefixAssignments),
      redirects: progress.redirects.concat(parts.redirects),
    });
  });
}

function readNextCommandPart(
  current: SimpleCommandAccumulator,
  token: Token,
): SimpleCommandAccumulator {
  if (isRedirectStart(current.state)) {
    return readRedirect(current);
  }

  if (
    token.kind === 'word' ||
    isProcessSubstitutionStart(current.state.tokens, current.state.index) ||
    (current.commandName !== null &&
      isParenthesizedWordStart(current.state.tokens, current.state.index))
  ) {
    return readSimpleCommandWord(current, token);
  }

  return readUnexpectedToken(current, token);
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
