import type { OperatorKind } from '../../../../../lexer';
import type { BaseNode } from '../../../../base';
import type { PipelineNode } from './pipeline';

export type SublistNode = BaseNode<'sublist'> & {
  readonly first: PipelineNode;
  readonly rest: readonly SublistContinuation[];
};

export type SublistContinuation = {
  readonly operator: LogicalOperatorNode;
  readonly pipeline: PipelineNode;
};

export type LogicalOperatorNode = BaseNode<'logicalOperator'> & {
  readonly type: Extract<OperatorKind, 'andIf' | 'orIf'>;
};
