import type { BaseNode } from '../base';
import type { WordNode } from '../word';

export type OptionNode = BaseNode<'option'> & {
  readonly name: string;
  readonly value: WordNode | null;
};
