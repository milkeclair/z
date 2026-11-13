import type { BaseNode } from '../../../../../../../base';
import type { VariableNameNode, VariableValueNode, WordNode } from '../../../../../../../word';

export type AssignNode = BaseNode<'assign'> & {
  readonly name: VariableNameNode;
  readonly subscript: WordNode | null;
  readonly operator: '=' | '+=';
  readonly value: VariableValueNode | null;
};
