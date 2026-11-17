import { List } from 'immutable';
import type { AstNode } from '..';
import { loop, again, done } from '../../../util/loop';

export type ChildCursor = { readonly node: AstNode; readonly tail: () => ChildCursor | null };
function one(node: AstNode | null | undefined): ChildCursor | null {
  return node ? { node, tail: () => null } : null;
}
function fromArray(nodes: readonly AstNode[], index = 0): ChildCursor | null {
  const node = nodes[index];
  return node ? { node, tail: () => fromArray(nodes, index + 1) } : null;
}
function concat(first: ChildCursor | null, rest: () => ChildCursor | null): ChildCursor | null {
  return first ? { node: first.node, tail: () => concat(first.tail(), rest) } : rest();
}
function many(...groups: readonly (ChildCursor | null)[]): ChildCursor | null {
  return groups.reduceRight<ChildCursor | null>((rest, group) => concat(group, () => rest), null);
}
function pairs<T>(
  items: readonly T[],
  select: (item: T) => readonly [AstNode, AstNode],
  index = 0,
): ChildCursor | null {
  const item = items[index];
  return item ? concat(fromArray(select(item)), () => pairs(items, select, index + 1)) : null;
}

export function syntaxChildCursor(node: AstNode): ChildCursor | null {
  switch (node.kind) {
    case 'file':
      return many(one(node.body), one(node.eof));
    case 'list':
      return fromArray(node.items);
    case 'listItem':
      return many(one(node.sublist), one(node.terminator));
    case 'sublist':
      return many(
        one(node.first),
        pairs(node.rest, (item) => [item.operator, item.pipeline]),
      );
    case 'pipeline':
      return many(
        one(node.timing),
        one(node.modifier),
        one(node.first),
        pairs(node.rest, (item) => [item.operator, item.command]),
      );
    case 'simpleCommand':
      return many(
        fromArray(node.precommandModifiers),
        fromArray(node.prefixAssignments),
        one(node.commandName),
        fromArray(node.arguments),
        fromArray(node.redirects),
      );
    case 'functionDefinition':
      return many(
        fromArray(node.options),
        fromArray(node.names),
        one(node.body),
        fromArray(node.postBodyRedirects),
      );
    case 'groupCommand':
      return many(one(node.body), one(node.always), fromArray(node.postBodyRedirects));
    case 'alwaysClause':
      return one(node.body);
    case 'subshellCommand':
      return many(one(node.body), fromArray(node.postBodyRedirects));
    case 'ifCommand':
      return many(fromArray(node.branches), one(node.elseBody), fromArray(node.postBodyRedirects));
    case 'ifBranch':
      return many(one(node.condition), one(node.body));
    case 'whileCommand':
    case 'untilCommand':
      return many(one(node.condition), one(node.body), fromArray(node.postBodyRedirects));
    case 'forCommand':
    case 'selectCommand':
    case 'foreachCommand':
      return many(
        fromArray(node.variables),
        fromArray(node.words ?? []),
        one(node.arithmetic),
        one(node.body),
        fromArray(node.postBodyRedirects),
      );
    case 'repeatCommand':
      return many(one(node.count), one(node.body), fromArray(node.postBodyRedirects));
    case 'caseCommand':
      return many(one(node.subject), fromArray(node.arms), fromArray(node.postBodyRedirects));
    case 'caseArm':
      return many(fromArray(node.patterns), one(node.body));
    case 'opaqueCommand':
      return fromArray(node.postBodyRedirects);
    case 'precommandModifier':
      return fromArray(node.options);
    case 'commandName':
      return one(node.word);
    case 'option':
      return one(node.value);
    case 'assign':
      return many(one(node.name), one(node.subscript), one(node.value));
    case 'variableValue':
      return one(node.value);
    case 'word':
      return fromArray(node.parts);
    case 'variableReference':
      return one(node.name);
    case 'commandSubstitution':
    case 'processSubstitution':
      return one(node.body);
    case 'redirect':
      return many(one(node.target), one(node.hereDocument));
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
      return null;
  }
  const exhaustive: never = node;
  return exhaustive;
}

function relatedOnly(node: AstNode): ChildCursor | null {
  switch (node.kind) {
    case 'file':
      return fromArray(node.comments);
    case 'functionDefinition':
      return one(node.leadingDoc);
    case 'docBlock':
      return fromArray(node.comments);
    case 'simpleCommand':
      if (node.semantic.role === 'source') {
        return one(node.semantic.source.target);
      }
      if (node.semantic.role === 'declaration') {
        return many(
          fromArray(node.semantic.declaration.options),
          fromArray(node.semantic.declaration.assignments),
          fromArray(node.semantic.declaration.names),
        );
      }
      return null;
    default:
      return null;
  }
}
export function relatedChildCursor(node: AstNode): ChildCursor | null {
  return concat(syntaxChildCursor(node), () => relatedOnly(node));
}

function cursorArray(cursor: ChildCursor | null): readonly AstNode[] {
  return loop<
    { readonly cursor: ChildCursor | null; readonly nodes: List<AstNode> },
    readonly AstNode[]
  >({ cursor, nodes: List() }, (state) =>
    state.cursor
      ? again({ cursor: state.cursor.tail(), nodes: state.nodes.push(state.cursor.node) })
      : done(state.nodes.toArray()),
  );
}
export function* syntaxChildren(node: AstNode): Generator<AstNode> {
  yield* cursorArray(syntaxChildCursor(node));
}
export function* withRelatedChildren(node: AstNode): Generator<AstNode> {
  yield* cursorArray(relatedChildCursor(node));
}
export function forEachChild(node: AstNode, visit: (child: AstNode) => void): void {
  loop<ChildCursor | null, void>(syntaxChildCursor(node), (cursor) => {
    if (!cursor) {
      return done(undefined);
    }
    visit(cursor.node);
    return again(cursor.tail());
  });
}
export function someChild(
  cursor: ChildCursor | null,
  predicate: (node: AstNode) => boolean,
): boolean {
  return loop<ChildCursor | null, boolean>(cursor, (current) =>
    !current ? done(false) : predicate(current.node) ? done(true) : again(current.tail()),
  );
}
