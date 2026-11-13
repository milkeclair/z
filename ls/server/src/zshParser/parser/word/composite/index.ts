import type { ListNode, WordNode } from '../../../ast';
import { Lexer } from '../../../lexer';
import type { ParserDiagnostic } from '../../diagnostic';
import { parseWithContext } from '../../parse';
import { mergeComments } from '../../comment';
import { rangeWithinText } from '../../range';
import type { SourceRange } from '../../../lexer';
import { advanceState } from '../../state';
import type { NodeResult, ParseState } from '../../state';
import { createWordNode } from '../index';
import { createCompositeWordNode } from './node';
import { readWordTokens } from './token';

export function readWordNode(state: ParseState): NodeResult<WordNode> {
  const result = readWordTokens({ tokens: state.tokens, index: state.index, collected: [] });
  const diagnostics: ParserDiagnostic[] = [];
  let comments = state.comments;
  const readBody = (raw: string, range: SourceRange): ListNode | null => {
    const prefix = raw.charCodeAt(0) === 96 ? 1 : 2;
    const closed = raw.endsWith(prefix === 1 ? String.fromCharCode(96) : ')');
    const content = raw.slice(prefix, closed ? -1 : undefined);
    const lexed = Lexer.tokenize(content, { sourceFile: state.sourceFile });
    const tokens = lexed.tokens.map((token) => ({
      ...token, range: rangeWithinText(range, raw, token.range.start.offset + prefix, token.range.end.offset + prefix),
      hereDoc: token.hereDoc ? { ...token.hereDoc, operatorOffset: token.hereDoc.operatorOffset + range.start.offset + prefix } : undefined,
    }));
    const parsed = parseWithContext(tokens, {
      sourceFile: state.sourceFile, comments,
      nesting: { depth: state.nesting.depth + 1, limit: state.nesting.limit },
    });
    diagnostics.push(...parsed.diagnostics, ...lexed.diagnostics.map((diagnostic): ParserDiagnostic => ({
      kind: 'unexpectedToken', message: diagnostic.message, sourceFile: state.sourceFile,
      range: rangeWithinText(range, raw, diagnostic.range.start.offset + prefix, diagnostic.range.end.offset + prefix),
    })));
    if (!closed) diagnostics.push({ kind: 'missingClosingParen', message: 'Missing substitution closing parenthesis', sourceFile: state.sourceFile, range });
    comments = mergeComments(comments, parsed.ast.comments);
    return parsed.ast.body;
  };
  const node = result.tokens.length === 1
    ? createWordNode(result.tokens[0], { readBody })
    : createCompositeWordNode(result.tokens, { readBody });
  const next = advanceState(state, result.nextIndex - state.index);
  return { node, state: { ...next, comments, stopped: next.stopped || diagnostics.some((item) => item.kind === 'nestingLimitExceeded'), diagnostics: [...next.diagnostics, ...diagnostics] } };
}
