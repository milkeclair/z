import type {
  AssignNode,
  DeclarationKind,
  DeclarationSyntaxMode,
  OptionNode,
  PrecommandModifierType,
  SimpleCommandSemantic,
  VariableNameNode,
  WordNode,
} from '../../../../../../../../ast';
import { rangeWithinText } from '../../../../../../../range';
import { createOptionNodeFromWord } from '../../../../../../../option';
import { createVariableNameNode, isVariableName } from '../../../../../../../word';
import { createAssignNodeFromWord } from '../assign';
import type { SimpleCommandSemanticInput } from '../types';

const Empty = '';
const Dash = '-';

export function createDeclarationSemantic(
  parts: SimpleCommandSemanticInput,
): SimpleCommandSemantic | null {
  const kind = declarationKind(parts.commandName?.value ?? Empty);

  if (!kind || hasPrecommandModifier(parts, 'command')) {
    return null;
  } else {
    return {
      role: 'declaration',
      declaration: {
        kind,
        syntaxMode: declarationSyntaxMode(parts),
        options: parts.arguments.flatMap(createDeclarationOption),
        assignments: parts.arguments.flatMap(createDeclarationAssignment),
        names: parts.arguments.flatMap(createDeclarationName),
      },
    };
  }
}

function declarationSyntaxMode(parts: SimpleCommandSemanticInput): DeclarationSyntaxMode {
  if (hasPrecommandModifier(parts, 'builtin')) {
    return 'builtinInterface';
  } else {
    return 'reservedWord';
  }
}

function hasPrecommandModifier(
  parts: SimpleCommandSemanticInput,
  type: PrecommandModifierType,
): boolean {
  return parts.precommandModifiers.some((modifier) => modifier.type === type);
}

function createDeclarationOption(word: WordNode): readonly OptionNode[] {
  if (word.raw.startsWith(Dash) && word.raw !== Dash) {
    return [createOptionNodeFromWord(word, null)];
  } else {
    return [];
  }
}

function createDeclarationAssignment(word: WordNode): readonly AssignNode[] {
  const assignment = createAssignNodeFromWord(word);

  if (assignment) {
    return [assignment];
  } else {
    return [];
  }
}

function createDeclarationName(word: WordNode): readonly VariableNameNode[] {
  if (isVariableName(word.raw) && !createAssignNodeFromWord(word)) {
    return [
      createVariableNameNode({
        value: word.raw,
        range: rangeWithinText(word.range, word.raw, 0, word.raw.length),
      }),
    ];
  } else {
    return [];
  }
}

function declarationKind(value: string): DeclarationKind | null {
  if (
    value === 'local' ||
    value === 'typeset' ||
    value === 'export' ||
    value === 'readonly' ||
    value === 'declare' ||
    value === 'integer' ||
    value === 'float'
  ) {
    return value;
  } else {
    return null;
  }
}
