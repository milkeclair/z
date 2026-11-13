import type { BaseNode } from '../base';
import type { CommentNode } from '../comment';
import type { EofNode } from '../eof';
import type { ListNode } from './list';

export type FileNode = BaseNode<'file'> & {
  readonly path: string;
  readonly body: ListNode;
  readonly comments: readonly CommentNode[];
  readonly eof: EofNode;
};
