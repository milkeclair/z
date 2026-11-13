import type { BaseNode } from '../base';
import type { SourceRange } from '../../lexer';

export type HereDocumentNode = BaseNode<'hereDocument'> & {
  readonly raw: string;
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly stripTabs: boolean;
  readonly close: SourceRange | null;
};
