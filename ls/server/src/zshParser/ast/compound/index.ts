import type { BaseNode } from '../base';
import type { SourceRange } from '../../lexer';
import type { ListNode } from '../file/list';
import type { WordNode, ArithmeticExpansionNode } from '../word';
import type { RedirectNode } from '../redirect';

type CompoundNode<Kind extends string> = BaseNode<Kind> & {
  readonly raw: string;
  readonly keyword: SourceRange;
  readonly close: SourceRange | null;
  readonly postBodyRedirects: readonly RedirectNode[];
};

export type IfBranchNode = BaseNode<'ifBranch'> & {
  readonly keyword: SourceRange;
  readonly condition: ListNode;
  readonly thenKeyword: SourceRange | null;
  readonly body: ListNode;
};
export type IfCommandNode = CompoundNode<'ifCommand'> & {
  readonly branches: readonly IfBranchNode[];
  readonly elseBody: ListNode | null;
};
type ConditionLoop<Kind extends string> = CompoundNode<Kind> & {
  readonly condition: ListNode;
  readonly body: ListNode;
};
export type WhileCommandNode = ConditionLoop<'whileCommand'>;
export type UntilCommandNode = ConditionLoop<'untilCommand'>;
type Iteration<Kind extends string> = CompoundNode<Kind> & {
  readonly variables: readonly WordNode[];
  readonly words: readonly WordNode[] | null;
  readonly arithmetic: ArithmeticExpansionNode | null;
  readonly body: ListNode;
};
export type ForCommandNode = Iteration<'forCommand'>;
export type SelectCommandNode = Iteration<'selectCommand'>;
export type ForeachCommandNode = Iteration<'foreachCommand'>;
export type RepeatCommandNode = CompoundNode<'repeatCommand'> & {
  readonly count: WordNode | null;
  readonly body: ListNode;
};
export type CaseArmNode = BaseNode<'caseArm'> & {
  readonly patterns: readonly WordNode[];
  readonly body: ListNode;
  readonly terminator: SourceRange | null;
  readonly termination: ';;' | ';&' | ';|' | null;
};
export type CaseCommandNode = CompoundNode<'caseCommand'> & {
  readonly subject: WordNode | null;
  readonly arms: readonly CaseArmNode[];
};
export type CompoundCommandNode = IfCommandNode | WhileCommandNode | UntilCommandNode |
  ForCommandNode | SelectCommandNode | ForeachCommandNode | RepeatCommandNode | CaseCommandNode;
