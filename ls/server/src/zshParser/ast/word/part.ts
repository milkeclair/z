import type { ProcessSubstitutionNode } from './processSubstitution';
import type { ArithmeticExpansionNode } from './arithmeticExpansion';
import type { CommandSubstitutionNode } from './commandSubstitution';
import type { ParameterExpansionNode } from './parameterExpansion';
import type { StringLiteralNode } from './stringLiteral';
import type { VariableReferenceNode } from './variableReference';

export type WordPartNode =
  | ProcessSubstitutionNode
  | StringLiteralNode
  | VariableReferenceNode
  | ParameterExpansionNode
  | CommandSubstitutionNode
  | ArithmeticExpansionNode;
