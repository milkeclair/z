import type { BaseNode } from '../base';
import type { ListNode } from '../list';

export type ProcessSubstitutionNode = BaseNode<'processSubstitution'> & {
  readonly raw: string;
  readonly direction: 'input' | 'output' | 'file';
  readonly body: ListNode | null;
};
