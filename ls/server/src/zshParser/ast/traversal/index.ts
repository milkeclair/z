import type {
  AstNode, FileNode, CommentNode, DocBlockNode, FunctionDefinitionNode,
} from '..';

export function* syntaxChildren(node: AstNode): Generator<AstNode> {
  switch (node.kind) {
    case 'file': yield node.body; yield node.eof; return;
    case 'list': yield* node.items; return;
    case 'listItem':
      yield node.sublist;
      if (node.terminator) yield node.terminator;
      return;
    case 'sublist':
      yield node.first;
      for (const rest of node.rest) { yield rest.operator; yield rest.pipeline; }
      return;
    case 'pipeline':
      if (node.timing) yield node.timing;
      if (node.modifier) yield node.modifier;
      yield node.first;
      for (const rest of node.rest) { yield rest.operator; yield rest.command; }
      return;
    case 'simpleCommand':
      yield* node.precommandModifiers; yield* node.prefixAssignments;
      if (node.commandName) yield node.commandName;
      yield* node.arguments; yield* node.redirects;
      return;
    case 'functionDefinition':
      yield* node.options; yield* node.names; yield node.body;
      yield* node.postBodyRedirects;
      return;
    case 'groupCommand':
      yield node.body;
      if (node.always) yield node.always;
      yield* node.postBodyRedirects;
      return;
    case 'alwaysClause': yield node.body; return;
    case 'subshellCommand': yield node.body; yield* node.postBodyRedirects; return;
    case 'ifCommand':
      yield* node.branches; if (node.elseBody) yield node.elseBody; yield* node.postBodyRedirects; return;
    case 'ifBranch': yield node.condition; yield node.body; return;
    case 'whileCommand':
    case 'untilCommand': yield node.condition; yield node.body; yield* node.postBodyRedirects; return;
    case 'forCommand':
    case 'selectCommand':
    case 'foreachCommand':
      yield* node.variables; if (node.words) yield* node.words;
      if (node.arithmetic) yield node.arithmetic;
      yield node.body; yield* node.postBodyRedirects; return;
    case 'repeatCommand': if (node.count) yield node.count; yield node.body; yield* node.postBodyRedirects; return;
    case 'caseCommand': if (node.subject) yield node.subject; yield* node.arms; yield* node.postBodyRedirects; return;
    case 'caseArm': yield* node.patterns; yield node.body; return;
    case 'opaqueCommand': yield* node.postBodyRedirects; return;
    case 'precommandModifier': yield* node.options; return;
    case 'commandName': yield node.word; return;
    case 'option': if (node.value) yield node.value; return;
    case 'assign':
      yield node.name;
      if (node.subscript) yield node.subscript;
      if (node.value) yield node.value;
      return;
    case 'variableValue': yield node.value; return;
    case 'word': yield* node.parts; return;
    case 'variableReference': yield node.name; return;
    case 'processSubstitution':
    case 'commandSubstitution': if (node.body) yield node.body; return;
    case 'redirect': if (node.target) yield node.target; if (node.hereDocument) yield node.hereDocument; return;
    case 'hereDocument':
    case 'docBlock':
    case 'comment':
    case 'eof':
    case 'unknown':
    case 'logicalOperator':
    case 'pipelineOperator':
    case 'pipelineModifier':
    case 'pipelineTiming':
    case 'terminator':
    case 'variableName':
    case 'stringLiteral':
    case 'parameterExpansion':
    case 'arithmeticExpansion':
      return;
  }
  const exhaustive: never = node;
  return exhaustive;
}

export function forEachChild(node: AstNode, visit: (child: AstNode) => void): void {
  for (const child of syntaxChildren(node)) visit(child);
}

export function* withRelatedChildren(node: AstNode): Generator<AstNode> {
  yield* syntaxChildren(node);
  switch (node.kind) {
    case 'file': yield* node.comments; break;
    case 'functionDefinition': if (node.leadingDoc) yield node.leadingDoc; break;
    case 'docBlock': yield* node.comments; break;
    case 'simpleCommand':
      if (node.semantic.role === 'source' && node.semantic.source.target) {
        yield node.semantic.source.target;
      } else if (node.semantic.role === 'declaration') {
        yield* node.semantic.declaration.options;
        yield* node.semantic.declaration.assignments;
        yield* node.semantic.declaration.names;
      }
      break;
  }
}

export type WalkControl = void | 'skip' | 'stop';
export type WalkOptions = { readonly includeRelated?: boolean };
type Frame = { readonly node: AstNode; readonly next: Iterator<AstNode>; readonly depth: number };

export function walk(
  root: AstNode,
  visit: (node: AstNode, depth: number) => WalkControl,
  options: WalkOptions = {},
): void {
  const stack: Frame[] = [];
  const seen = options.includeRelated ? new WeakSet<AstNode>() : null;

  function enter(node: AstNode, depth: number): boolean {
    if (seen?.has(node)) return true;
    seen?.add(node);
    const action = visit(node, depth);
    if (action === 'stop') return false;
    if (action !== 'skip') {
      const next = options.includeRelated ? withRelatedChildren(node) : syntaxChildren(node);
      stack.push({ node, next, depth });
    }
    return true;
  }

  if (!enter(root, 0)) return;
  while (stack.length > 0) {
    const frame = stack[stack.length - 1];
    const child = frame.next.next();
    if (child.done) stack.pop();
    else if (!enter(child.value, frame.depth + 1)) return;
  }
}

function hasKind<K extends AstNode['kind']>(
  node: AstNode, kind: K,
): node is Extract<AstNode, { readonly kind: K }> {
  return node.kind === kind;
}

export function findAll<K extends AstNode['kind']>(
  root: AstNode, kind: K, options: WalkOptions = {},
): readonly Extract<AstNode, { readonly kind: K }>[] {
  const found: Extract<AstNode, { readonly kind: K }>[] = [];
  walk(root, node => { if (hasKind(node, kind)) found.push(node); }, options);
  return found;
}

type DocContext = {
  readonly docBlock: DocBlockNode;
  readonly target: FunctionDefinitionNode;
};
export type QueryContext = {
  readonly file: FileNode;
  readonly documentationByOffset: ReadonlyMap<number, DocContext>;
};

export function createQueryContext(file: FileNode): QueryContext {
  const entries = file.comments.length === 0 ? [] : findAll(file, 'functionDefinition').flatMap(target => {
    const docBlock = target.leadingDoc;
    if (!docBlock) return [];
    const context: DocContext = { docBlock, target };
    return docBlock.comments.map((comment): readonly [number, DocContext] =>
      [comment.range.start.offset, context]);
  });
  return { file, documentationByOffset: new Map(entries) };
}

export function commentAt(file: FileNode, offset: number): CommentNode | null {
  if (!Number.isSafeInteger(offset)) return null;
  let low = 0, high = file.comments.length - 1;
  while (low <= high) {
    const middle = Math.floor((low + high) / 2);
    const comment = file.comments[middle];
    if (offset < comment.range.start.offset) high = middle - 1;
    else if (offset >= comment.range.end.offset) low = middle + 1;
    else return comment;
  }
  return null;
}

export type AstLocation =
  | { readonly kind: 'syntax'; readonly node: AstNode; readonly path: readonly AstNode[] }
  | { readonly kind: 'comment'; readonly node: CommentNode; readonly docBlock: DocBlockNode | null; readonly target: FunctionDefinitionNode | null };

type PositionScore = { readonly owned: boolean; readonly start: number; readonly end: number };
type PositionFrame = Frame & { readonly parent: PositionFrame | null; readonly score: PositionScore };

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
  const fallback: PositionScore = { owned: false, start: node.range.start.offset, end: node.range.end.offset };
  switch (node.kind) {
    case 'file': case 'list': case 'listItem': case 'sublist': case 'pipeline': case 'simpleCommand':
    case 'word': case 'commandName': case 'precommandModifier': case 'option': case 'assign': case 'variableValue':
      return fallback;
    case 'functionDefinition': return mark(node.openParen, offset) ?? mark(node.closeParen, offset) ?? fallback;
    case 'groupCommand': return mark(node.openBrace, offset) ?? mark(node.closeBrace, offset) ?? fallback;
    case 'subshellCommand': return mark(node.openParen, offset) ?? mark(node.closeParen, offset) ?? fallback;
    case 'alwaysClause': return mark(node.keyword, offset) ?? fallback;
    case 'ifBranch': return mark(node.keyword, offset) ?? mark(node.thenKeyword, offset) ?? fallback;
    case 'ifCommand': case 'whileCommand': case 'untilCommand': case 'forCommand':
    case 'selectCommand': case 'foreachCommand': case 'repeatCommand': case 'caseCommand':
      return mark(node.keyword, offset) ?? mark(node.close, offset) ?? fallback;
    case 'caseArm': return mark(node.terminator, offset) ?? fallback;
    case 'opaqueCommand':
      return ownedSpan(node.open.start.offset, node.close?.end.offset ?? node.range.end.offset, offset) ?? fallback;
    case 'redirect': {
      const headerEnd = node.target?.range.end.offset ?? node.range.start.offset + node.operator.length;
      return ownedSpan(node.range.start.offset, headerEnd, offset) ??
        (node.hereDocument ? ownedSpan(node.hereDocument.range.start.offset, node.hereDocument.close?.end.offset ?? node.hereDocument.range.end.offset, offset) : null) ??
        fallback;
    }
    case 'commandSubstitution':
    case 'processSubstitution': {
      const backtick = node.raw.charCodeAt(0) === 96;
      const opening = ownedSpan(node.range.start.offset, node.range.start.offset + (backtick ? 1 : 2), offset);
      const closed = node.raw.endsWith(backtick ? String.fromCharCode(96) : ')');
      return opening ?? (closed ? ownedSpan(node.range.end.offset - 1, node.range.end.offset, offset) : null) ?? fallback;
    }
    case 'hereDocument': case 'comment': case 'docBlock': case 'eof': case 'unknown':
    case 'logicalOperator': case 'pipelineOperator': case 'pipelineModifier': case 'pipelineTiming':
    case 'terminator': case 'variableName': case 'stringLiteral': case 'variableReference':
    case 'parameterExpansion': case 'arithmeticExpansion':
      return { ...fallback, owned: true };
  }
  const exhaustive: never = node;
  return exhaustive;
}
function betterPosition(candidate: PositionFrame, best: PositionFrame): boolean {
  if (candidate.score.owned !== best.score.owned) return candidate.score.owned;
  if (!candidate.score.owned && candidate.score.start !== best.score.start) return candidate.score.start > best.score.start;
  const width = candidate.score.end - candidate.score.start;
  const previousWidth = best.score.end - best.score.start;
  return width < previousWidth || width === previousWidth && candidate.depth > best.depth;
}

export function locate(query: QueryContext, offset: number): AstLocation | null {
  const file = query.file;
  if (!Number.isSafeInteger(offset)) return null;
  if (offset < file.range.start.offset || offset > file.range.end.offset) return null;
  if (offset === file.eof.range.start.offset) {
    return { kind: 'syntax', node: file.eof, path: [file, file.eof] };
  }
  const comment = commentAt(file, offset);
  if (comment) {
    const context = query.documentationByOffset.get(comment.range.start.offset);
    return { kind: 'comment', node: comment, docBlock: context?.docBlock ?? null, target: context?.target ?? null };
  }
  if (!contains(file, offset)) return null;
  const first: PositionFrame = { node: file, next: syntaxChildren(file), depth: 0, parent: null, score: positionScore(file, offset) };
  const stack: PositionFrame[] = [first];
  let best = first;
  while (stack.length > 0) {
    const parent = stack[stack.length - 1];
    const candidate = parent.next.next();
    if (candidate.done) { stack.pop(); continue; }
    if (!contains(candidate.value, offset)) continue;
    const score = positionScore(candidate.value, offset);
    const inherited = !score.owned && parent.score.owned && score.start === parent.score.start && score.end === parent.score.end;
    const child: PositionFrame = {
      node: candidate.value, next: syntaxChildren(candidate.value),
      depth: parent.depth + 1, parent, score: inherited ? { ...score, owned: true } : score,
    };
    stack.push(child);
    if (betterPosition(child, best)) best = child;
  }
  const path: AstNode[] = [];
  for (let frame: PositionFrame | null = best; frame; frame = frame.parent) path.push(frame.node);
  path.reverse();
  return { kind: 'syntax', node: best.node, path };
}
