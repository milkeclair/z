import type { SourceRange } from '../../../../../../../lexer';
import type { BaseNode } from '../../../../../../base';
import type { RedirectNode } from '../../../../../../redirect';

export type OpaqueCommandSyntax = 'condition' | 'arithmetic';

export type OpaqueCommandNode = BaseNode<'opaqueCommand'> & {
  readonly syntax: OpaqueCommandSyntax;
  readonly raw: string;
  readonly open: SourceRange;
  readonly close: SourceRange | null;
  readonly postBodyRedirects: readonly RedirectNode[];
};
