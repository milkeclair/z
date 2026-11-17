import type { CaseArmNode, CompoundCommandNode, IfBranchNode } from './command/compound';
import type { FunctionDefinitionNode } from './command/function';
import type { AlwaysClauseNode, GroupCommandNode } from './command/group';
import type { OpaqueCommandNode } from './command/opaque';
import type {
  AssignNode,
  CommandNameNode,
  PrecommandModifierNode,
  SimpleCommandNode,
} from './command/simple';
import type { SubshellCommandNode } from './command/subshell';
import type { CommentNode } from './comment';
import type { DocBlockNode } from './docBlock';
import type { EofNode } from './eof';
import type { FileNode } from './file';
import type { ListNode } from './list';
import type { ListItemNode, ListTerminatorNode } from './listItem';
import type { OptionNode } from './option';
import type {
  PipelineModifierNode,
  PipelineNode,
  PipelineOperatorNode,
  PipelineTimingNode,
} from './pipeline';
import type { HereDocumentNode, RedirectNode } from './redirect';
import type { LogicalOperatorNode, SublistNode } from './sublist';
import type { UnknownNode } from './unknown';
import type {
  ArithmeticExpansionNode,
  CommandSubstitutionNode,
  ParameterExpansionNode,
  ProcessSubstitutionNode,
  StringLiteralNode,
  VariableNameNode,
  VariableReferenceNode,
  VariableValueNode,
  WordNode,
} from './word';

export type AstNode =
  | FileNode
  | CompoundCommandNode
  | IfBranchNode
  | CaseArmNode
  | ListNode
  | ListItemNode
  | SublistNode
  | LogicalOperatorNode
  | PipelineNode
  | PipelineOperatorNode
  | PipelineModifierNode
  | PipelineTimingNode
  | ListTerminatorNode
  | SimpleCommandNode
  | FunctionDefinitionNode
  | GroupCommandNode
  | AlwaysClauseNode
  | SubshellCommandNode
  | OpaqueCommandNode
  | PrecommandModifierNode
  | CommandNameNode
  | OptionNode
  | AssignNode
  | VariableNameNode
  | VariableValueNode
  | WordNode
  | ProcessSubstitutionNode
  | StringLiteralNode
  | VariableReferenceNode
  | ParameterExpansionNode
  | CommandSubstitutionNode
  | ArithmeticExpansionNode
  | RedirectNode
  | HereDocumentNode
  | CommentNode
  | DocBlockNode
  | UnknownNode
  | EofNode;

export type AstNodeKind = AstNode['kind'];
