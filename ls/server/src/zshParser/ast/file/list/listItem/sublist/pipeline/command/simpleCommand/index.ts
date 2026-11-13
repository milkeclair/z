import type { BaseNode } from '../../../../../../../base';
import type { OptionNode } from '../../../../../../../option';
import type { RedirectNode } from '../../../../../../../redirect';
import type { WordNode } from '../../../../../../../word';
import type { AssignNode } from './assign';
import type { CommandNameNode } from './commandName';
import type { PrecommandModifierNode } from './precommandModifier';
import type { SimpleCommandSemantic } from './semantic';

export type SimpleCommandNode = BaseNode<'simpleCommand'> & {
  readonly precommandModifiers: readonly PrecommandModifierNode[];
  readonly prefixAssignments: readonly AssignNode[];
  readonly commandName: CommandNameNode | null;
  readonly arguments: readonly WordNode[];
  readonly redirects: readonly RedirectNode[];
  readonly semantic: SimpleCommandSemantic;
};

export type { AssignNode } from './assign';
export type { CommandNameNode } from './commandName';
export type { PrecommandModifierNode, PrecommandModifierType } from './precommandModifier';
export type {
  DeclarationInfo,
  DeclarationKind,
  DeclarationSyntaxMode,
  SimpleCommandSemantic,
  SourceInfo,
} from './semantic';
