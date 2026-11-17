import type { Token } from '../../lexer';
import type { CommentContext } from '../comment';
import type { ParserDiagnostic } from '../diagnostic';
import type { NestingState } from './nesting';

export type ParseOptions = {
  readonly sourceFile?: string;
  readonly path?: string;
  readonly nesting?: NestingState;
};

export type ParseStateOptions = ParseOptions & { readonly comments?: CommentContext };

export type ParseState = {
  readonly nesting: NestingState;
  readonly stopped: boolean;
  readonly comments: CommentContext;
  readonly tokens: readonly Token[];
  readonly index: number;
  readonly sourceFile: string;
  readonly diagnostics: readonly ParserDiagnostic[];
  readonly eof: Token;
};

export type NodeResult<Node> = {
  readonly node: Node;
  readonly state: ParseState;
};
