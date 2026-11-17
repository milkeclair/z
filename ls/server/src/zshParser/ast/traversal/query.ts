import { List } from 'immutable';
import { loop, again, done } from '../../../util/loop';
import { lowerBound } from '../../../util/search';
import type { AstNode, CommentNode, DocBlockNode, FileNode, FunctionDefinitionNode } from '..';
import { syntaxChildCursor } from './children';
import { findAll, type TraversalFrame } from './walk';

type DocContext = {
  readonly docBlock: DocBlockNode;
  readonly target: FunctionDefinitionNode;
};

export type QueryContext = {
  readonly file: FileNode;
  readonly documentationByOffset: ReadonlyMap<number, DocContext>;
};

export function createQueryContext(file: FileNode): QueryContext {
  const entries =
    file.comments.length === 0
      ? []
      : findAll(file, 'functionDefinition').flatMap((target) => {
          const docBlock = target.leadingDoc;
          if (!docBlock) {
            return [];
          }
          const context: DocContext = { docBlock, target };
          return docBlock.comments.map((comment): readonly [number, DocContext] => [
            comment.range.start.offset,
            context,
          ]);
        });
  return { file, documentationByOffset: new Map(entries) };
}

export function commentAt(file: FileNode, offset: number): CommentNode | null {
  if (!Number.isSafeInteger(offset)) {
    return null;
  }
  const index = lowerBound(
    file.comments.length,
    (index) => file.comments[index].range.end.offset <= offset,
  );
  const comment = file.comments[index];
  return comment && comment.range.start.offset <= offset ? comment : null;
}

export type AstLocation =
  | { readonly kind: 'syntax'; readonly node: AstNode; readonly path: readonly AstNode[] }
  | {
      readonly kind: 'comment';
      readonly node: CommentNode;
      readonly docBlock: DocBlockNode | null;
      readonly target: FunctionDefinitionNode | null;
    };

type PositionScore = { readonly owned: boolean; readonly start: number; readonly end: number };

type PositionFrame = TraversalFrame & {
  readonly parent: PositionFrame | null;
  readonly score: PositionScore;
};

function contains(node: AstNode, offset: number): boolean {
  return node.range.start.offset <= offset && offset < node.range.end.offset;
}

function ownedSpan(start: number, end: number, offset: number): PositionScore | null {
  return start <= offset && offset < end ? { owned: true, start, end } : null;
}

function mark(range: AstNode['range'] | null, offset: number): PositionScore | null {
  return range ? ownedSpan(range.start.offset, range.end.offset, offset) : null;
}

function positionScore(node: AstNode, offset: number): PositionScore {
  const fallback: PositionScore = {
    owned: false,
    start: node.range.start.offset,
    end: node.range.end.offset,
  };
  switch (node.kind) {
    case 'file':
    case 'list':
    case 'listItem':
    case 'sublist':
    case 'pipeline':
    case 'simpleCommand':
    case 'word':
    case 'commandName':
    case 'precommandModifier':
    case 'option':
    case 'assign':
    case 'variableValue':
      return fallback;
    case 'functionDefinition':
      return mark(node.openParen, offset) ?? mark(node.closeParen, offset) ?? fallback;
    case 'groupCommand':
      return mark(node.openBrace, offset) ?? mark(node.closeBrace, offset) ?? fallback;
    case 'subshellCommand':
      return mark(node.openParen, offset) ?? mark(node.closeParen, offset) ?? fallback;
    case 'alwaysClause':
      return mark(node.keyword, offset) ?? fallback;
    case 'ifBranch':
      return mark(node.keyword, offset) ?? mark(node.thenKeyword, offset) ?? fallback;
    case 'ifCommand':
    case 'whileCommand':
    case 'untilCommand':
    case 'forCommand':
    case 'selectCommand':
    case 'foreachCommand':
    case 'repeatCommand':
    case 'caseCommand':
      return mark(node.keyword, offset) ?? mark(node.close, offset) ?? fallback;
    case 'caseArm':
      return mark(node.terminator, offset) ?? fallback;
    case 'opaqueCommand':
      return (
        ownedSpan(
          node.open.start.offset,
          node.close?.end.offset ?? node.range.end.offset,
          offset,
        ) ?? fallback
      );
    case 'redirect': {
      const headerEnd =
        node.target?.range.end.offset ?? node.range.start.offset + node.operator.length;
      return (
        ownedSpan(node.range.start.offset, headerEnd, offset) ??
        (node.hereDocument
          ? ownedSpan(
              node.hereDocument.range.start.offset,
              node.hereDocument.close?.end.offset ?? node.hereDocument.range.end.offset,
              offset,
            )
          : null) ??
        fallback
      );
    }
    case 'commandSubstitution':
    case 'processSubstitution': {
      const backtick = node.raw.charCodeAt(0) === 96;
      const opening = ownedSpan(
        node.range.start.offset,
        node.range.start.offset + (backtick ? 1 : 2),
        offset,
      );
      const closed = node.raw.endsWith(backtick ? String.fromCharCode(96) : ')');
      return (
        opening ??
        (closed ? ownedSpan(node.range.end.offset - 1, node.range.end.offset, offset) : null) ??
        fallback
      );
    }
    case 'hereDocument':
    case 'comment':
    case 'docBlock':
    case 'eof':
    case 'unknown':
    case 'logicalOperator':
    case 'pipelineOperator':
    case 'pipelineModifier':
    case 'pipelineTiming':
    case 'terminator':
    case 'variableName':
    case 'stringLiteral':
    case 'variableReference':
    case 'parameterExpansion':
    case 'arithmeticExpansion':
      return { ...fallback, owned: true };
  }
  const exhaustive: never = node;
  return exhaustive;
}

function betterPosition(candidate: PositionFrame, best: PositionFrame): boolean {
  if (candidate.score.owned !== best.score.owned) {
    return candidate.score.owned;
  }
  if (!candidate.score.owned && candidate.score.start !== best.score.start) {
    return candidate.score.start > best.score.start;
  }
  const width = candidate.score.end - candidate.score.start;
  const previousWidth = best.score.end - best.score.start;
  return width < previousWidth || (width === previousWidth && candidate.depth > best.depth);
}

export function locate(query: QueryContext, offset: number): AstLocation | null {
  const file = query.file;
  if (!Number.isSafeInteger(offset)) {
    return null;
  }
  if (offset < file.range.start.offset || offset > file.range.end.offset) {
    return null;
  }
  if (offset === file.eof.range.start.offset) {
    return { kind: 'syntax', node: file.eof, path: [file, file.eof] };
  }
  const comment = commentAt(file, offset);
  if (comment) {
    const context = query.documentationByOffset.get(comment.range.start.offset);
    return {
      kind: 'comment',
      node: comment,
      docBlock: context?.docBlock ?? null,
      target: context?.target ?? null,
    };
  }
  if (!contains(file, offset)) {
    return null;
  }
  const first: PositionFrame = {
    node: file,
    children: syntaxChildCursor(file),
    depth: 0,
    parent: null,
    score: positionScore(file, offset),
  };
  const initial = { stack: List([first]), best: first };
  const best = loop<typeof initial, PositionFrame>(initial, (progress) => {
    const parent = progress.stack.last();
    if (!parent) {
      return done(progress.best);
    }
    const candidate = parent.children;
    if (!candidate) {
      return again({ ...progress, stack: progress.stack.pop() });
    }
    const advanced = { ...parent, children: candidate.tail() };
    const remaining = progress.stack.set(-1, advanced);
    if (!contains(candidate.node, offset)) {
      return again({ ...progress, stack: remaining });
    }
    const score = positionScore(candidate.node, offset);
    const inherited =
      !score.owned &&
      parent.score.owned &&
      score.start === parent.score.start &&
      score.end === parent.score.end;
    const child: PositionFrame = {
      node: candidate.node,
      children: syntaxChildCursor(candidate.node),
      depth: parent.depth + 1,
      parent,
      score: inherited ? { ...score, owned: true } : score,
    };
    return again({
      stack: remaining.push(child),
      best: betterPosition(child, progress.best) ? child : progress.best,
    });
  });
  const path = loop<
    { readonly frame: PositionFrame | null; readonly nodes: List<AstNode> },
    readonly AstNode[]
  >({ frame: best, nodes: List() }, (progress) =>
    progress.frame
      ? again({ frame: progress.frame.parent, nodes: progress.nodes.push(progress.frame.node) })
      : done(progress.nodes.reverse().toArray()),
  );
  return { kind: 'syntax', node: best.node, path };
}
