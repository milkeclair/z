import type { SourceRange } from '../../lexer';
import type { BaseNode } from '../base';

export type HereDocumentNode = BaseNode<'hereDocument'> & {
  readonly raw: string;
  readonly delimiter: string;
  readonly quoted: boolean;
  readonly stripTabs: boolean;
  readonly close: SourceRange | null;
};
