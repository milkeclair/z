import type { BaseNode } from '../base';

export type StringLiteralNode = BaseNode<'stringLiteral'> & {
  readonly value: string;
};
