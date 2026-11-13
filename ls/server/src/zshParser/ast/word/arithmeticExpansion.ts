import type { BaseNode } from '../base';

export type ArithmeticExpansionNode = BaseNode<'arithmeticExpansion'> & {
  readonly raw: string;
};
