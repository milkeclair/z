import type { BaseNode } from '../base';
import type { ListNode } from '../file/list';

export type CommandSubstitutionNode = BaseNode<'commandSubstitution'> & {
  readonly raw: string;
  readonly body: ListNode | null;
};
