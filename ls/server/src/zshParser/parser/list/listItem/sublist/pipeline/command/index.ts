import { enterNesting } from '../../../../../state/nesting';
import { isCompoundStart, parseCompoundCommand } from './compound';
import type { CommandNode } from '../../../../../../ast';
import { isCommandBoundary } from '../../../../../boundary';
import { addDiagnostic, currentToken, skipTrivia } from '../../../../../state';
import type { NodeResult, ParseState } from '../../../../../state';
import type { ParserContext } from '../../../../../context';
import { isFunctionDefinitionStart, parseFunctionDefinition } from './functionDefinition';
import { parseGroupCommand } from './group';
import { parseOpaqueCommandIfStart } from './opaque';
import { parseSimpleCommand } from './simpleCommand';
import { parseSubshellCommand } from './subshell';
import { createUnknownCommand } from './unknown';

export function parseCommand(input: {
  readonly state: ParseState; readonly context: ParserContext; readonly readPostBodyRedirects?: boolean;
}): NodeResult<CommandNode> {
  const state = skipTrivia(input.state);
  const nesting = enterNesting(state.nesting);
  if (state.stopped || nesting.kind === 'limit') {
    const diagnosed = state.stopped ? state : addDiagnostic({ state, kind: 'nestingLimitExceeded', message: 'Parser nesting limit exceeded', tokens: [currentToken(state)] });
    return {
      node: { kind: 'unknown', reason: 'nestingLimitExceeded', range: { start: currentToken(state).range.start, end: state.eof.range.end } },
      state: { ...diagnosed, stopped: true, index: state.tokens.length - 1 },
    };
  }
  const result = parseCommandInside({ ...input, state: { ...state, nesting: nesting.state } });
  return { node: result.node, state: { ...result.state, nesting: state.nesting } };
}

function parseCommandInside({
  state,
  context,
  readPostBodyRedirects = true,
}: {
  readonly state: ParseState;
  readonly context: ParserContext;
  readonly readPostBodyRedirects?: boolean;
}): NodeResult<CommandNode> {
  const current = skipTrivia(state);
  const token = currentToken(current);

  if (token.kind === 'eof') {
    return createUnknownCommand(current, token, 'Unexpected EOF in command');
  } else if (token.operatorKind === 'rightBrace' || token.operatorKind === 'rightParen') {
    return createUnknownCommand(
      current,
      token,
      `Unexpected token in command: ${token.value}`,
      { consume: false },
    );
  } else if (isCommandBoundary(token)) {
    return createUnknownCommand(current, token, `Unexpected token in command: ${token.value}`);
  } else if (isFunctionDefinitionStart(current)) {
    return parseFunctionDefinition({
      state: current,
      parseBodyCommand: (bodyState) =>
        parseCommand({
          state: bodyState,
          context,
          readPostBodyRedirects: false,
        }),
    });
  } else if (token.operatorKind === 'leftBrace') {
    return parseGroupCommand({
      state: current,
      context,
      readPostBodyRedirects,
    });
  } else if (token.operatorKind === 'leftParen') {
    return parseSubshellCommand({
      state: current,
      context,
      readPostBodyRedirects,
    });
  } else if (isCompoundStart(token)) {
    return parseCompoundCommand({ state: current, context, readPostBodyRedirects });
  } else {
    const opaqueCommand = parseOpaqueCommandIfStart({
      state: current,
      readPostBodyRedirects,
    });

    if (opaqueCommand) {
      return opaqueCommand;
    } else {
      return parseSimpleCommand(current);
    }
  }
}
