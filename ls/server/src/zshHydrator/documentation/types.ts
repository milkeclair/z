import type { SourceRange } from '../../zshParser/lexer';

type DocNode<Kind extends string> = {
  readonly kind: Kind;
  readonly range: SourceRange;
  readonly raw: string;
};
type ParameterBase<Kind extends string> = DocNode<Kind> & {
  readonly optional: boolean;
  readonly description: string;
  readonly markerRange: SourceRange;
};
export type PositionalParameterDoc = ParameterBase<'positionalParameterDoc'> & { readonly position: number };
export type NamedParameterDoc = ParameterBase<'namedParameterDoc'> & { readonly name: string };
export type RestParameterDoc = ParameterBase<'restParameterDoc'> & { readonly parameter: '@' | '*' };
export type ParameterDoc = PositionalParameterDoc | NamedParameterDoc | RestParameterDoc;
export type DocDescription = DocNode<'docDescription'> & { readonly text: string };
export type DocReply = DocNode<'docReply'> & { readonly text: string };
export type DocReturn = DocNode<'docReturn'> & { readonly text: string };
export type DocExample = DocNode<'docExample'> & { readonly text: string };
export type DocumentationNode = ParameterDoc | DocDescription | DocReply | DocReturn | DocExample;
export type HydrationDiagnostic = {
  readonly kind: 'invalidParameterDoc';
  readonly range: SourceRange;
  readonly message: string;
};
export type FunctionDocumentation = DocNode<'functionDocumentation'> & {
  readonly description: readonly DocDescription[];
  readonly parameters: readonly ParameterDoc[];
  readonly reply: DocReply | null;
  readonly returns: DocReturn | null;
  readonly examples: readonly DocExample[];
  readonly diagnostics: readonly HydrationDiagnostic[];
};
