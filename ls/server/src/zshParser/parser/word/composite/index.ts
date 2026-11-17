import * as Immutable from 'immutable';
import { createWordNode } from '..';
import type { ListNode, WordNode, WordPartNode } from '../../../ast';
import type { SourceRange } from '../../../lexer';
import { Lexer } from '../../../lexer';
import { mergeComments, type CommentContext } from '../../comment';
import type { ParserDiagnostic } from '../../diagnostic';
import { parseWithContext } from '../../parse';
import { rangeWithinText } from '../../range';
import type { NodeResult, ParseState } from '../../state';
import { advanceState } from '../../state';
import { createCompositeWordNode } from './node';
import { readWordTokens } from './token';

type BodyResult = {
  readonly body: ListNode;
  readonly comments: CommentContext;
  readonly diagnostics: readonly ParserDiagnostic[];
};

function readSubstitutionBody(
  raw: string,
  range: SourceRange,
  state: ParseState,
  comments: CommentContext,
): BodyResult {
  const prefix = raw.charCodeAt(0) === 96 ? 1 : 2;
  const closed = raw.endsWith(prefix === 1 ? String.fromCharCode(96) : ')');
  const content = raw.slice(prefix, closed ? -1 : undefined);
  const lexed = Lexer.tokenize(content, { sourceFile: state.sourceFile });
  const tokens = lexed.tokens.map((token) => ({
    ...token,
    range: rangeWithinText(
      range,
      raw,
      token.range.start.offset + prefix,
      token.range.end.offset + prefix,
    ),
    hereDoc: token.hereDoc
      ? {
          ...token.hereDoc,
          operatorOffset: token.hereDoc.operatorOffset + range.start.offset + prefix,
        }
      : undefined,
  }));
  const parsed = parseWithContext(tokens, {
    sourceFile: state.sourceFile,
    comments,
    nesting: { depth: state.nesting.depth + 1, limit: state.nesting.limit },
  });
  const lexical = lexed.diagnostics.map(
    (diagnostic): ParserDiagnostic => ({
      kind: 'unexpectedToken',
      message: diagnostic.message,
      sourceFile: state.sourceFile,
      range: rangeWithinText(
        range,
        raw,
        diagnostic.range.start.offset + prefix,
        diagnostic.range.end.offset + prefix,
      ),
    }),
  );
  const closing: readonly ParserDiagnostic[] = closed
    ? []
    : [
        {
          kind: 'missingClosingParen',
          message: 'Missing substitution closing parenthesis',
          sourceFile: state.sourceFile,
          range,
        },
      ];

  return {
    body: parsed.ast.body,
    comments: mergeComments(comments, parsed.ast.comments),
    diagnostics: [...parsed.diagnostics, ...lexical, ...closing],
  };
}

export function readWordNode(state: ParseState): NodeResult<WordNode> {
  const result = readWordTokens({ tokens: state.tokens, index: state.index, collected: [] });
  const syntax =
    result.tokens.length === 1
      ? createWordNode(result.tokens[0])
      : createCompositeWordNode(result.tokens);
  const parsed = syntax.parts.reduce(
    (previous, part) => {
      if (part.kind !== 'commandSubstitution' && part.kind !== 'processSubstitution') {
        return { ...previous, parts: previous.parts.push(part) };
      }

      const body = readSubstitutionBody(part.raw, part.range, state, previous.comments);

      return {
        parts: previous.parts.push({ ...part, body: body.body }),
        comments: body.comments,
        diagnostics: previous.diagnostics.concat(body.diagnostics),
      };
    },
    {
      parts: Immutable.List<WordPartNode>(),
      comments: state.comments,
      diagnostics: Immutable.List<ParserDiagnostic>(),
    },
  );
  const next = advanceState(state, result.nextIndex - state.index);

  return {
    node: { ...syntax, parts: parsed.parts.toArray() },
    state: {
      ...next,
      comments: parsed.comments,
      stopped:
        next.stopped || parsed.diagnostics.some((item) => item.kind === 'nestingLimitExceeded'),
      diagnostics: [...next.diagnostics, ...parsed.diagnostics],
    },
  };
}
