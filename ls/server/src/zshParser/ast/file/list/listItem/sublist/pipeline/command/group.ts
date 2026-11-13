import type { UnknownNode } from '../../../../../../unknown';
import type { SourceRange } from '../../../../../../../lexer';
import type { BaseNode } from '../../../../../../base';
import type { RedirectNode } from '../../../../../../redirect';
import type { ListNode } from '../../../..';

export type GroupCommandNode = BaseNode<'groupCommand'> & {
  readonly openBrace: SourceRange;
  readonly body: ListNode;
  readonly closeBrace: SourceRange | null;
  readonly always: AlwaysClauseNode | null;
  readonly postBodyRedirects: readonly RedirectNode[];
};

export type AlwaysClauseNode = BaseNode<'alwaysClause'> & {
  readonly keyword: SourceRange;
  readonly body: GroupCommandNode | UnknownNode;
};
