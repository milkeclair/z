import type { SourceRange } from '../../lexer';
import type { BaseNode } from '../base';
import type { CommentNode } from '../comment';

export type DocBlockNode = BaseNode<'docBlock'> & {
  readonly comments: readonly CommentNode[];
  readonly targetRange: SourceRange;
};
