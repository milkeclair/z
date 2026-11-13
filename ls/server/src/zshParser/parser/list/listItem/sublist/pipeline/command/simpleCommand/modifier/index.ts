import type {
  OptionNode,
  PrecommandModifierNode,
  PrecommandModifierType,
} from '../../../../../../../../ast';
import type { Token } from '../../../../../../../../lexer';
import { createOptionNodeFromToken } from '../../../../../../../option';
import {
  advanceState,
  currentToken,
  skipInlineTrivia,
} from '../../../../../../../state';
import type { NodeResult, ParseState } from '../../../../../../../state';
import { readWordNode } from '../../../../../../../word/composite';
import { isProcessSubstitutionStart } from '../../../../../../../word/composite/token';

const Dash = '-';

export function precommandModifierType(value: string): PrecommandModifierType | null {
  if (value === Dash) {
    return 'dash';
  } else if (
    value === 'builtin' ||
    value === 'command' ||
    value === 'exec' ||
    value === 'noglob' ||
    value === 'nocorrect'
  ) {
    return value;
  } else {
    return null;
  }
}

export function readPrecommandModifierNode(
  state: ParseState,
  type: PrecommandModifierType,
): NodeResult<PrecommandModifierNode> {
  const token = currentToken(state);
  const result = readPrecommandOptions({
    state: advanceState(state),
    type,
    options: [],
  });

  return {
    node: {
      kind: 'precommandModifier',
      range: precommandModifierRange(token.range, result.options),
      type,
      options: result.options,
    },
    state: result.state,
  };
}

type OptionsResult = {
  readonly options: readonly OptionNode[];
  readonly state: ParseState;
};

function readPrecommandOptions({
  state,
  type,
  options,
}: {
  readonly state: ParseState;
  readonly type: PrecommandModifierType;
  readonly options: readonly OptionNode[];
}): OptionsResult {
  const result = [...options];
  let current = state;
  while (true) {
    const candidate = skipInlineTrivia(current);
    const option = createPrecommandOption(type, currentToken(candidate), candidate);
    if (!option) return { options: result, state: current };
    result.push(option.node); current = option.state;
  }
}

function createPrecommandOption(
  type: PrecommandModifierType,
  token: Token,
  state: ParseState,
): NodeResult<OptionNode> | null {
  if (token.kind !== 'word') {
    return null;
  } else if (type === 'command' && isCommandOption(token.value)) {
    return {
      node: createOptionNodeFromToken(token, null),
      state: advanceState(state),
    };
  } else if (type === 'exec' && isExecValueOption(token.value)) {
    return createExecValueOption(token, state);
  } else if (type === 'exec' && isExecFlagOption(token.value)) {
    return {
      node: createOptionNodeFromToken(token, null),
      state: advanceState(state),
    };
  } else {
    return null;
  }
}

function createExecValueOption(token: Token, state: ParseState): NodeResult<OptionNode> {
  const valueState = skipInlineTrivia(advanceState(state));
  const valueToken = currentToken(valueState);

  if (valueToken.kind === 'word' || isProcessSubstitutionStart(valueState.tokens, valueState.index)) {
    const value = readWordNode(valueState);

    return {
      node: createOptionNodeFromToken(token, value.node),
      state: value.state,
    };
  } else {
    return {
      node: createOptionNodeFromToken(token, null),
      state: advanceState(state),
    };
  }
}

function precommandModifierRange(
  range: PrecommandModifierNode['range'],
  options: PrecommandModifierNode['options'],
): PrecommandModifierNode['range'] {
  const lastOption = options[options.length - 1];

  if (lastOption) {
    return {
      start: range.start,
      end: lastOption.range.end,
    };
  } else {
    return range;
  }
}

function isCommandOption(value: string): boolean {
  return value.length > 1 && value[0] === Dash && containsOnlyCommandOptionChars(value, 1);
}

function isExecValueOption(value: string): boolean {
  return value === '-a';
}

function isExecFlagOption(value: string): boolean {
  return value.length > 1 && value[0] === Dash && containsOnlyExecFlagOptionChars(value, 1);
}

function containsOnlyCommandOptionChars(value: string, index: number): boolean {
  for (let cursor = index; cursor < value.length; cursor += 1) if (!'pvV'.includes(value[cursor])) return false;
  return true;
}

function containsOnlyExecFlagOptionChars(value: string, index: number): boolean {
  for (let cursor = index; cursor < value.length; cursor += 1) if (!'cl'.includes(value[cursor])) return false;
  return true;
}
