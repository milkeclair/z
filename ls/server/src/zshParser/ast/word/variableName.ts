import type { BaseNode } from '../base';

export type VariableNameNode = BaseNode<'variableName'> & {
  readonly value: string;
};
