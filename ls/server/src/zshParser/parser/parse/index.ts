import type { ParseStateOptions } from '../state/types';
import type { FileNode } from '../../ast';
import type { Token } from '../../lexer';
import { createEofNode } from '../eof';
import { parseList } from '../list';
import { rangeFromTokens } from '../range';
import { createParseState } from '../state';
import type { ParseOptions } from '../state';
import type { ParserDiagnostic } from '../diagnostic';

export type ParseResult = {
  readonly ast: FileNode;
  readonly tokens: readonly Token[];
  readonly diagnostics: readonly ParserDiagnostic[];
};

export function parse(tokens: readonly Token[], options: ParseOptions = {}): ParseResult {
  return parseWithContext(tokens, options);
}

export function parseWithContext(tokens: readonly Token[], options: ParseStateOptions): ParseResult {
  const state = createParseState(tokens, options);
  const bodyResult = parseList(state, isFileEnd);
  const eof = createEofNode(bodyResult.state.eof);
  const allTokens = bodyResult.state.tokens;
  const fileRange = rangeFromTokens(allTokens, eof.range);

  return {
    ast: {
      kind: 'file',
      range: fileRange,
      path: options.path ?? state.sourceFile,
      body: bodyResult.node,
      comments: bodyResult.state.comments.comments,
      eof,
    },
    tokens: allTokens,
    diagnostics: bodyResult.state.diagnostics,
  };
}

export type { ParseOptions, ParserDiagnostic };

function isFileEnd(token: Token): boolean {
  return token.kind === 'eof';
}
