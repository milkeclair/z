import type {
  CaseCommandNode,
  ForCommandNode,
  ForeachCommandNode,
  IfCommandNode,
  RepeatCommandNode,
  SelectCommandNode,
  UntilCommandNode,
  WhileCommandNode,
} from '../../../ast';
export type CompoundContents =
  | Pick<IfCommandNode, 'kind' | 'branches' | 'elseBody'>
  | Pick<WhileCommandNode | UntilCommandNode, 'kind' | 'condition' | 'body'>
  | Pick<
      ForCommandNode | SelectCommandNode | ForeachCommandNode,
      'kind' | 'variables' | 'words' | 'arithmetic' | 'body'
    >
  | Pick<RepeatCommandNode, 'kind' | 'count' | 'body'>
  | Pick<CaseCommandNode, 'kind' | 'subject' | 'arms'>;
