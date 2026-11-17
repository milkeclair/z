import * as Immutable from 'immutable';
import type { AstNode, FileNode } from '../../../src/zshParser/ast';
import { foldAst } from '../../../src/zshParser/ast';
import type { SourcePosition, SourceRange, Token } from '../../../src/zshParser/lexer';

export function astContractViolations(
  ast: FileNode,
  tokens: readonly Token[],
  source: string,
): readonly string[] {
  const lines = [
    0,
    ...Immutable.Range(0, source.length)
      .filter(
        (index) => source[index] === '\n' || (source[index] === '\r' && source[index + 1] !== '\n'),
      )
      .map((index) => index + 1),
  ];

  function validPosition(position: SourcePosition): boolean {
    if (
      !Number.isSafeInteger(position.offset) ||
      position.offset < 0 ||
      position.offset > source.length
    ) {
      return false;
    }

    const upper = (low: number, high: number): number => {
      if (low >= high) {
        return low;
      }

      const middle = Math.floor((low + high) / 2);

      return lines[middle] <= position.offset ? upper(middle + 1, high) : upper(low, middle);
    };
    const line = upper(0, lines.length) - 1;

    return position.line === line && position.character === position.offset - lines[line];
  }

  function validRange(range: SourceRange): boolean {
    return (
      validPosition(range.start) &&
      validPosition(range.end) &&
      range.start.offset <= range.end.offset
    );
  }

  const coverage = tokens.reduce(
    (previous, token) => {
      const valid =
        validRange(token.range) &&
        token.range.start.offset === previous.cursor &&
        token.value === source.slice(token.range.start.offset, token.range.end.offset);

      return {
        cursor: token.range.end.offset,
        issues: valid ? previous.issues : previous.issues.push('tokenCoverage'),
      };
    },
    { cursor: 0, issues: Immutable.List<string>() },
  );
  const comments = new Map(ast.comments.map((comment) => [comment.range.start.offset, comment]));
  const initial = coverage.issues.concat([
    ...(coverage.cursor !== source.length || tokens.at(-1)?.kind !== 'eof'
      ? ['tokenCoverage']
      : []),
    ...(ast.range.start.offset !== 0 || ast.range.end.offset !== source.length
      ? ['fileRange']
      : []),
    ...(ast.eof.range.start.offset !== source.length || ast.eof.range.end.offset !== source.length
      ? ['eofRange']
      : []),
    ...(comments.size !== ast.comments.length ? ['duplicateComment'] : []),
  ]);

  function nodeIssues(node: AstNode): readonly string[] {
    const basic = [
      ...(!validRange(node.range) ? ['nodeRange:' + node.kind] : []),
      ...(node.kind === 'unknown' ? ['unknown'] : []),
      ...('raw' in node && node.raw !== source.slice(node.range.start.offset, node.range.end.offset)
        ? ['rawRange:' + node.kind]
        : []),
      ...(node.kind === 'stringLiteral' &&
      node.value !== source.slice(node.range.start.offset, node.range.end.offset)
        ? ['literalRange']
        : []),
    ];
    const parts =
      node.kind === 'word'
        ? node.parts.reduce(
            (previous, part) => ({
              offset: part.range.end.offset,
              issues:
                part.range.start.offset === previous.offset
                  ? previous.issues
                  : previous.issues.push('wordPartCoverage'),
            }),
            { offset: node.range.start.offset, issues: Immutable.List<string>() },
          )
        : null;
    const word =
      node.kind === 'word'
        ? [
            ...(node.parts
              .map((part) =>
                part.kind === 'stringLiteral'
                  ? part.value
                  : part.kind === 'variableReference'
                    ? part.sigil + part.name.value
                    : part.raw,
              )
              .join('') !== node.raw
              ? ['wordParts']
              : []),
            ...(parts?.issues ?? []),
            ...(parts?.offset !== node.range.end.offset ? ['wordPartCoverage'] : []),
          ]
        : [];
    const docs =
      node.kind === 'functionDefinition' && node.leadingDoc
        ? node.leadingDoc.comments
            .filter((comment) => comments.get(comment.range.start.offset) !== comment)
            .map(() => 'commentIdentity')
        : [];
    const semantic =
      node.kind === 'simpleCommand' &&
      node.semantic.role === 'source' &&
      node.semantic.source.target !== (node.arguments[0] ?? null)
        ? ['sourceIdentity']
        : [];

    return [...basic, ...word, ...docs, ...semantic];
  }

  return foldAst(ast, initial, (previous, node) => ({ state: previous.concat(nodeIssues(node)) }), {
    includeRelated: true,
  }).toArray();
}
