import type { CompoundCommandNode, IfBranchNode, CaseArmNode } from './compound';
import type { CommentNode } from './comment';
import type { DocBlockNode } from './docBlock';
import type { EofNode } from './eof';
import type { FileNode } from './file';
import type { ListNode } from './file/list';
import type {
  ListItemNode,
  ListTerminatorNode,
} from './file/list/listItem';
import type {
  LogicalOperatorNode,
  SublistNode,
} from './file/list/listItem/sublist';
import type {
  PipelineModifierNode,
  PipelineNode,
  PipelineOperatorNode,
  PipelineTimingNode,
} from './file/list/listItem/sublist/pipeline';
import type { FunctionDefinitionNode } from './file/list/listItem/sublist/pipeline/command/functionDefinition';
import type {
  AlwaysClauseNode,
  GroupCommandNode,
} from './file/list/listItem/sublist/pipeline/command/group';
import type { OpaqueCommandNode } from './file/list/listItem/sublist/pipeline/command/opaque';
import type {
  AssignNode,
  CommandNameNode,
  PrecommandModifierNode,
  SimpleCommandNode,
} from './file/list/listItem/sublist/pipeline/command/simpleCommand';
import type { SubshellCommandNode } from './file/list/listItem/sublist/pipeline/command/subshell';
import type { OptionNode } from './option';
import type { RedirectNode, HereDocumentNode } from './redirect';
import type { UnknownNode } from './unknown';
import type {
  ArithmeticExpansionNode,
  CommandSubstitutionNode,
  ParameterExpansionNode,
  StringLiteralNode,
  VariableNameNode,
  VariableReferenceNode,
  VariableValueNode,
  WordNode,
  ProcessSubstitutionNode,
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
