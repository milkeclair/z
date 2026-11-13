import type { OptionNode } from '../../../../../../../option';
import type { VariableNameNode, WordNode } from '../../../../../../../word';
import type { AssignNode } from './assign';

export type SimpleCommandSemantic =
  | { readonly role: 'normal' }
  | { readonly role: 'source'; readonly source: SourceInfo }
  | { readonly role: 'declaration'; readonly declaration: DeclarationInfo };

export type SourceInfo = {
  readonly form: 'source' | 'dot';
  readonly target: WordNode | null;
};

export type DeclarationKind =
  | 'local'
  | 'typeset'
  | 'export'
  | 'readonly'
  | 'declare'
  | 'integer'
  | 'float';

export type DeclarationSyntaxMode = 'reservedWord' | 'builtinInterface';

export type DeclarationInfo = {
  readonly kind: DeclarationKind;
  readonly syntaxMode: DeclarationSyntaxMode;
  readonly options: readonly OptionNode[];
  readonly assignments: readonly AssignNode[];
  readonly names: readonly VariableNameNode[];
};
