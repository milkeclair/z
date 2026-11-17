import type { ListNode } from '../../../..';
import type { SourceRange } from '../../../../../../../lexer';
import type { BaseNode } from '../../../../../../base';
import type { RedirectNode } from '../../../../../../redirect';

export type SubshellCommandNode = BaseNode<'subshellCommand'> & {
  readonly openParen: SourceRange;
  readonly body: ListNode;
  readonly closeParen: SourceRange | null;
  readonly postBodyRedirects: readonly RedirectNode[];
};
