import type { BaseNode } from '../../../../../../../base';
import type { OptionNode } from '../../../../../../../option';

export type PrecommandModifierType =
  | 'dash'
  | 'builtin'
  | 'command'
  | 'exec'
  | 'noglob'
  | 'nocorrect';

export type PrecommandModifierNode = BaseNode<'precommandModifier'> & {
  readonly type: PrecommandModifierType;
  readonly options: readonly OptionNode[];
};
