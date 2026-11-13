import type { CommandNameNode, WordNode } from '../../../../../../../ast';
import type { Token } from '../../../../../../../lexer';
import { readWordNode } from '../../../../../../word/composite';
import { createAssignNodeFromWord } from './assign';
import { precommandModifierType, readPrecommandModifierNode } from './modifier';
import type { SimpleCommandAccumulator } from './types';

export function readSimpleCommandWord(
  parts: SimpleCommandAccumulator,
  token: Token,
): SimpleCommandAccumulator {
  const modifierType = parts.commandName ? null : precommandModifierType(token.value);
  const word = readWordNode(parts.state);
  const assignment = createAssignNodeFromWord(word.node);

  if (modifierType && canReadPrecommandModifier(parts, modifierType)) {
    const modifier = readPrecommandModifierNode(parts.state, modifierType);

    return {
      ...parts,
      state: modifier.state,
      syntaxEndIndex: modifier.state.index,
      precommandModifiers: [...parts.precommandModifiers, modifier.node],
    };
  } else if (!parts.commandName && assignment) {
    return {
      ...parts,
      state: word.state,
      syntaxEndIndex: word.state.index,
      prefixAssignments: [...parts.prefixAssignments, assignment],
    };
  } else if (!parts.commandName) {
    return {
      ...parts,
      state: word.state,
      syntaxEndIndex: word.state.index,
      commandName: createCommandNameNode(word.node),
    };
  } else {
    return {
      ...parts,
      state: word.state,
      syntaxEndIndex: word.state.index,
      arguments: [...parts.arguments, word.node],
    };
  }
}

function canReadPrecommandModifier(
  parts: SimpleCommandAccumulator,
  modifierType: NonNullable<ReturnType<typeof precommandModifierType>>,
): boolean {
  return modifierType !== 'nocorrect' || parts.precommandModifiers.length === 0;
}

function createCommandNameNode(word: WordNode): CommandNameNode {
  return {
    kind: 'commandName',
    range: word.range,
    value: word.raw,
    word,
  };
}
