import type { BaseNode } from '../../base';
import type { ListItemNode } from './listItem';

export type ListNode = BaseNode<'list'> & {
  readonly items: readonly ListItemNode[];
};
