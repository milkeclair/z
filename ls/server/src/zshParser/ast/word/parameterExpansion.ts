import type { BaseNode } from '../base';

export type ParameterExpansionNode = BaseNode<'parameterExpansion'> & {
  readonly raw: string;
};
