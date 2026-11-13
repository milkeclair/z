import type { BaseNode } from '../base';
import type { WordNode } from './word';

export type VariableValueNode = BaseNode<'variableValue'> & {
  readonly value: WordNode;
};
