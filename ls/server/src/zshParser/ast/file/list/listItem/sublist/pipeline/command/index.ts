import type { CompoundCommandNode } from '../../../../../../compound';
import type { UnknownNode } from '../../../../../../unknown';
import type { FunctionDefinitionNode } from './functionDefinition';
import type { GroupCommandNode } from './group';
import type { OpaqueCommandNode } from './opaque';
import type { SimpleCommandNode } from './simpleCommand';
import type { SubshellCommandNode } from './subshell';

export type CommandNode =
  | CompoundCommandNode
  | SimpleCommandNode
  | FunctionDefinitionNode
  | GroupCommandNode
  | SubshellCommandNode
  | OpaqueCommandNode
  | UnknownNode;
