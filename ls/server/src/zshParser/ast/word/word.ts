import type { QuoteKind } from '../../lexer';
import type { BaseNode } from '../base';
import type { WordPartNode } from './part';

export type WordNode = BaseNode<'word'> & {
  readonly raw: string;
  readonly quoted: boolean;
  readonly quoteKind: QuoteKind;
  readonly parts: readonly WordPartNode[];
};
