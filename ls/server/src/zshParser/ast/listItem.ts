import type { BaseNode } from './base';
import type { PipelineNode } from './pipeline';
import type { SublistNode } from './sublist';
import type { UnknownNode } from './unknown';

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

/** 前景で実行される項目から、論理演算やパイプの連結を持たないコマンドを取得する。 */
export function standalonePipeline(item: ListItemNode): PipelineNode | null {
  const { sublist, terminator } = item;
  const foreground =
    !terminator || terminator.type === 'newline' || terminator.type === 'semicolon';

  if (sublist.kind !== 'sublist' || !foreground || sublist.rest.length) {
    return null;
  }

  const pipeline = sublist.first;

  return !pipeline.modifier && pipeline.rest.length === 0 ? pipeline : null;
}
