import type { OperatorKind } from '../../../../../../lexer';
import type { BaseNode } from '../../../../../base';
import type { CommandNode } from './command';

export type PipelineNode = BaseNode<'pipeline'> & {
  readonly timing: PipelineTimingNode | null;
  readonly modifier: PipelineModifierNode | null;
  readonly first: CommandNode;
  readonly rest: readonly PipelineContinuation[];
};

export type PipelineContinuation = {
  readonly operator: PipelineOperatorNode;
  readonly command: CommandNode;
};

export type PipelineOperatorNode = BaseNode<'pipelineOperator'> & {
  readonly type: Extract<OperatorKind, 'pipe' | 'pipeErr'>;
};

export type PipelineModifierNode = BaseNode<'pipelineModifier'> & {
  readonly type: 'bang' | 'coproc';
};

export type PipelineTimingNode = BaseNode<'pipelineTiming'>;
