import { DefaultNestingLimit } from './nesting';
import { createCommentContext } from '../comment';
import type { SourcePosition, Token } from '../../lexer';
import { ZeroPosition } from '../range';
import type { ParseStateOptions, ParseState } from './types';

const Empty = '';

export function createParseState(tokens: readonly Token[], options: ParseStateOptions = {}): ParseState {
  const nesting = options.nesting ?? { depth: 0, limit: DefaultNestingLimit };
  if (!Number.isSafeInteger(nesting.depth) || nesting.depth < 0 || !Number.isSafeInteger(nesting.limit) || nesting.limit < 1) {
    throw new RangeError('Parser nesting depth and limit must be non-negative/positive safe integers');
  }
  const sourceFile = options.sourceFile ?? tokens[0]?.sourceFile ?? Empty;
  const normalized = normalizeTokens(tokens, sourceFile);
  const eof = normalized[normalized.length - 1] ?? createEofToken(sourceFile, ZeroPosition);

  return {
    nesting,
    stopped: false,
    comments: createCommentContext(normalized, options.comments),
    tokens: normalized,
    index: 0,
    sourceFile,
    diagnostics: [],
    eof,
  };
}

function normalizeTokens(tokens: readonly Token[], sourceFile: string): readonly Token[] {
  const last = tokens[tokens.length - 1];

  if (last?.kind === 'eof') {
    return tokens;
  } else {
    return [...tokens, createEofToken(sourceFile, last?.range.end ?? ZeroPosition)];
  }
}

function createEofToken(sourceFile: string, position: SourcePosition): Token {
  return {
    kind: 'eof',
    value: Empty,
    sourceFile,
    range: {
      start: position,
      end: position,
    },
    quoted: false,
    quoteKind: 'none',
    operatorKind: undefined,
  };
}
