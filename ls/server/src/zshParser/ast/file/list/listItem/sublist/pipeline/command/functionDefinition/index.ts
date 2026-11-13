import type { SourceRange } from '../../../../../../../../lexer';
import type { BaseNode } from '../../../../../../../base';
import type { DocBlockNode } from '../../../../../../../docBlock';
import type { OptionNode } from '../../../../../../../option';
import type { RedirectNode } from '../../../../../../../redirect';
import type { WordNode } from '../../../../../../../word';
import type { CommandNode } from '..';

export type FunctionDefinitionForm = 'functionKeyword' | 'shCompatible';

export type FunctionDefinitionNode = BaseNode<'functionDefinition'> & {
  readonly form: FunctionDefinitionForm;
  readonly options: readonly OptionNode[];
  readonly names: readonly WordNode[];
  readonly openParen: SourceRange | null;
  readonly closeParen: SourceRange | null;
  readonly body: FunctionBodyNode;
  readonly postBodyRedirects: readonly RedirectNode[];
  readonly leadingDoc: DocBlockNode | null;
};

export type FunctionBodyNode = CommandNode;
