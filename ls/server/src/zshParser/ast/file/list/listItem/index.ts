import type { BaseNode } from '../../../base';
import type { UnknownNode } from '../../../unknown';
import type { SublistNode } from './sublist';

export type ListItemNode = BaseNode<'listItem'> & {
  readonly sublist: SublistNode | UnknownNode;
  readonly terminator: ListTerminatorNode | null;
};

export type ListTerminatorType =
  | 'newline'
  | 'semicolon'
  | 'background'
  | 'backgroundPipe'
  | 'backgroundBang';

export type ListTerminatorNode = BaseNode<'terminator'> & {
  readonly type: ListTerminatorType;
};
