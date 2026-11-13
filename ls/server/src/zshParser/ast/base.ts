import type { SourceRange } from '../lexer';

export type BaseNode<Kind extends string> = {
  readonly kind: Kind;
  readonly range: SourceRange;
};
