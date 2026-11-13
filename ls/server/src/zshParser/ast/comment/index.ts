import type { BaseNode } from '../base';

export type CommentNode = BaseNode<'comment'> & {
  readonly text: string;
};
