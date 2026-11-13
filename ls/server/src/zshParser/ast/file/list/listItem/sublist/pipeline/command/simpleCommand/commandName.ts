import type { BaseNode } from '../../../../../../../base';
import type { WordNode } from '../../../../../../../word';

export type CommandNameNode = BaseNode<'commandName'> & {
  readonly value: string;
  readonly word: WordNode;
};
