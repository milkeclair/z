import type { FileNode } from '../../../src/zshParser/ast';
import { walk } from '../../../src/zshParser/ast';
import type { SourcePosition, SourceRange, Token } from '../../../src/zshParser/lexer';

export function astContractViolations(ast: FileNode, tokens: readonly Token[], source: string): readonly string[] {
  const issues: string[] = [];
  const lines = [0];
  for (let index = 0; index < source.length; index += 1) {
    if (source[index] === '\n' || source[index] === '\r' && source[index + 1] !== '\n') lines.push(index + 1);
  }
  function validPosition(position: SourcePosition): boolean {
    if (!Number.isSafeInteger(position.offset) || position.offset < 0 || position.offset > source.length) return false;
    let low = 0; let high = lines.length;
    while (low < high) {
      const middle = Math.floor((low + high) / 2);
      if (lines[middle] <= position.offset) low = middle + 1;
      else high = middle;
    }
    const line = low - 1;
    return position.line === line && position.character === position.offset - lines[line];
  }
  function validRange(range: SourceRange): boolean {
    return validPosition(range.start) && validPosition(range.end) && range.start.offset <= range.end.offset;
  }
  let cursor = 0;
  for (const token of tokens) {
    if (!validRange(token.range) || token.range.start.offset !== cursor ||
      token.value !== source.slice(token.range.start.offset, token.range.end.offset)) issues.push('tokenCoverage');
    cursor = token.range.end.offset;
  }
  if (cursor !== source.length || tokens.at(-1)?.kind !== 'eof') issues.push('tokenCoverage');
  if (ast.range.start.offset !== 0 || ast.range.end.offset !== source.length) issues.push('fileRange');
  if (ast.eof.range.start.offset !== source.length || ast.eof.range.end.offset !== source.length) issues.push('eofRange');
  const comments = new Map(ast.comments.map((comment) => [comment.range.start.offset, comment]));
  if (comments.size !== ast.comments.length) issues.push('duplicateComment');
  walk(ast, (node) => {
    if (!validRange(node.range)) issues.push('nodeRange:' + node.kind);
    if (node.kind === 'unknown') issues.push('unknown');
    if ('raw' in node && node.raw !== source.slice(node.range.start.offset, node.range.end.offset)) issues.push('rawRange:' + node.kind);
    if (node.kind === 'stringLiteral' && node.value !== source.slice(node.range.start.offset, node.range.end.offset)) issues.push('literalRange');
    if (node.kind === 'word') {
      const raw = node.parts.map((part) => part.kind === 'stringLiteral' ? part.value
        : part.kind === 'variableReference' ? part.sigil + part.name.value : part.raw).join('');
      if (raw !== node.raw) issues.push('wordParts');
      let offset = node.range.start.offset;
      for (const part of node.parts) {
        if (part.range.start.offset !== offset) issues.push('wordPartCoverage');
        offset = part.range.end.offset;
      }
      if (offset !== node.range.end.offset) issues.push('wordPartCoverage');
    }
    if (node.kind === 'functionDefinition' && node.leadingDoc) {
      for (const comment of node.leadingDoc.comments) if (comments.get(comment.range.start.offset) !== comment) issues.push('commentIdentity');
    }
    if (node.kind === 'simpleCommand' && node.semantic.role === 'source' && node.semantic.source.target !== (node.arguments[0] ?? null)) issues.push('sourceIdentity');
  }, { includeRelated: true });
  return issues;
}
