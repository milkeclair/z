import type {
  FunctionDefinitionForm,
  OptionNode,
  WordNode,
} from '../../../../../../../ast';
import type { SourceRange, Token } from '../../../../../../../lexer';
import { createOptionNodeFromToken } from '../../../../../../option';
import {
  addDiagnostic,
  advanceState,
  currentToken,
  skipTrivia,
} from '../../../../../../state';
import type { ParseState } from '../../../../../../state';
import { createWordNode } from '../../../../../../word';
import { isFunctionKeyword } from './detect';

type HeaderResult = {
  readonly form: FunctionDefinitionForm;
  readonly options: readonly OptionNode[];
  readonly names: readonly WordNode[];
  readonly openParen: SourceRange | null;
  readonly closeParen: SourceRange | null;
  readonly state: ParseState;
};

export function readFunctionHeader(state: ParseState): HeaderResult {
  if (isFunctionKeyword(currentToken(state))) {
    return readFunctionKeywordHeader(state);
  } else {
    return readShCompatibleHeader(state);
  }
}

function readFunctionKeywordHeader(state: ParseState): HeaderResult {
  const afterKeyword = skipTrivia(advanceState(state));
  const options = readFunctionOptions({
    state: afterKeyword,
    options: [],
  });
  const names = readFunctionNames({
    state: options.state,
    names: [],
  });
  const parens = readOptionalParens(names.state);

  return {
    form: 'functionKeyword',
    options: options.options,
    names: names.names,
    openParen: parens.openParen,
    closeParen: parens.closeParen,
    state: parens.state,
  };
}

function readFunctionOptions({
  state,
  options,
}: {
  readonly state: ParseState;
  readonly options: readonly OptionNode[];
}): { readonly options: readonly OptionNode[]; readonly state: ParseState } {
  const result = [...options];
  let current = skipTrivia(state);
  while (currentToken(current).kind === 'word' && currentToken(current).value === '-T') {
    result.push(createOptionNodeFromToken(currentToken(current), null));
    current = skipTrivia(advanceState(current));
  }
  return { options: result, state: current };
}

function readFunctionNames({
  state,
  names,
}: {
  readonly state: ParseState;
  readonly names: readonly WordNode[];
}): { readonly names: readonly WordNode[]; readonly state: ParseState } {
  const result = [...names];
  let current = skipTrivia(state);
  while (currentToken(current).kind === 'word' && !isFunctionKeyword(currentToken(current))) {
    result.push(createWordNode(currentToken(current)));
    current = skipTrivia(advanceState(current));
  }
  return { names: result, state: current };
}

function readOptionalParens(state: ParseState): {
  readonly openParen: SourceRange | null;
  readonly closeParen: SourceRange | null;
  readonly state: ParseState;
} {
  const current = skipTrivia(state);
  const openParen = currentToken(current);

  if (openParen.operatorKind !== 'leftParen') {
    return {
      openParen: null,
      closeParen: null,
      state: current,
    };
  } else {
    return readCloseParen(current, openParen);
  }
}

function readCloseParen(
  state: ParseState,
  openParen: Token,
): {
  readonly openParen: SourceRange;
  readonly closeParen: SourceRange | null;
  readonly state: ParseState;
} {
  const closeState = skipTrivia(advanceState(state));
  const closeParen = currentToken(closeState);

  if (closeParen.operatorKind === 'rightParen') {
    return {
      openParen: openParen.range,
      closeParen: closeParen.range,
      state: advanceState(closeState),
    };
  } else {
    const diagnosed = addDiagnostic({
      state: closeState,
      kind: 'missingClosingParen',
      message: 'Missing closing parenthesis in function definition',
      tokens: [openParen],
    });

    return {
      openParen: openParen.range,
      closeParen: null,
      state: diagnosed,
    };
  }
}

function readShCompatibleHeader(state: ParseState): HeaderResult {
  const names = readFunctionNames({
    state,
    names: [],
  });
  const parens = readOptionalParens(names.state);

  return {
    form: 'shCompatible',
    options: [],
    names: names.names,
    openParen: parens.openParen,
    closeParen: parens.closeParen,
    state: parens.state,
  };
}
