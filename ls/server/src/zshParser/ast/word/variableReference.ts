import type { BaseNode } from '../base';
import type { VariableNameNode } from './variableName';

export type VariableReferenceNode = BaseNode<'variableReference'> & {
  readonly sigil: '$';
  readonly name: VariableNameNode;
};
