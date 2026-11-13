import type {
  CommandNode,
  FunctionBodyNode,
  FunctionDefinitionNode,
  UnknownNode,
} from '../../../../../../../ast';
import type { Token } from '../../../../../../../lexer';
import { readPostCommandRedirects } from '../../../../../../redirect';
import { rangeFromTokens, enclosingRange } from '../../../../../../range';
import {
  addDiagnostic,
  currentToken,
  skipTrivia,
  tokenSlice,
} from '../../../../../../state';
import type { NodeResult, ParseState } from '../../../../../../state';
import { skipCommandTerm } from '../term';
import { createLeadingDocBlock } from './docBlock';
import { isFunctionDefinitionStart } from './detect';
import { readFunctionHeader } from './header';

type ParseCommand = (state: ParseState) => NodeResult<CommandNode>;

export { isFunctionDefinitionStart };

export function parseFunctionDefinition({
  state,
  parseBodyCommand,
}: {
  readonly state: ParseState;
  readonly parseBodyCommand: ParseCommand;
}): NodeResult<FunctionDefinitionNode> {
  const startState = skipTrivia(state);
  const startIndex = startState.index;
  const header = readFunctionHeader(startState);
  const body = readFunctionBody({
    state: skipCommandTerm(header.state),
    parseBodyCommand,
  });
  const postBodyRedirects = readPostCommandRedirects(body.state);
  const tokens = tokenSlice(postBodyRedirects.state, startIndex, postBodyRedirects.state.index);
  const functionRange = enclosingRange(rangeFromTokens(tokens, body.node.range), [body.node, ...postBodyRedirects.redirects]);
  const leadingDoc = createLeadingDocBlock({
    context: postBodyRedirects.state.comments,
    tokens: postBodyRedirects.state.tokens,
    targetIndex: startIndex,
    targetRange: functionRange,
  });

  return {
    node: {
      kind: 'functionDefinition',
      range: functionRange,
      form: header.form,
      options: header.options,
      names: header.names,
      openParen: header.openParen,
      closeParen: header.closeParen,
      body: body.node,
      postBodyRedirects: postBodyRedirects.redirects,
      leadingDoc,
    },
    state: postBodyRedirects.state,
  };
}

function readFunctionBody({
  state,
  parseBodyCommand,
}: {
  readonly state: ParseState;
  readonly parseBodyCommand: ParseCommand;
}): NodeResult<FunctionBodyNode> {
  const current = skipTrivia(state);
  const token = currentToken(current);

  if (token.kind === 'eof' || token.kind === 'newline' || token.operatorKind === 'semicolon') {
    return createMissingFunctionBody(current, token);
  } else {
    return parseBodyCommand(current);
  }
}

function createMissingFunctionBody(
  state: ParseState,
  token: Token,
): NodeResult<UnknownNode> {
  const diagnosed = addDiagnostic({
    state,
    kind: 'missingFunctionBody',
    message: 'Missing function body',
    tokens: [token],
  });

  return {
    node: {
      kind: 'unknown',
      range: token.range,
      reason: 'missingFunctionBody',
    },
    state: diagnosed,
  };
}
