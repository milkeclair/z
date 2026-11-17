import { List, Set as PersistentSet } from 'immutable';
import type { AstNode } from '..';
import { again, done, loop } from '../../../util/loop';
import { pushStack, type Stack } from '../../../util/stack';
import { relatedChildCursor, syntaxChildCursor, type ChildCursor } from './children';

export type WalkControl = void | 'skip' | 'stop';
export type WalkOptions = { readonly includeRelated?: boolean };
export type TraversalFrame = {
  readonly node: AstNode;
  readonly children: ChildCursor | null;
  readonly depth: number;
};
type Task =
  | { readonly kind: 'node'; readonly node: AstNode; readonly depth: number }
  | { readonly kind: 'children'; readonly cursor: ChildCursor | null; readonly depth: number };
export type FoldStep<State> = { readonly state: State; readonly control?: WalkControl };
type FoldProgress<State> = {
  readonly result: State;
  readonly tasks: Stack<Task> | null;
  readonly seen: PersistentSet<AstNode> | null;
};

export function foldAst<State>(
  root: AstNode,
  initial: State,
  reduce: (state: State, node: AstNode, depth: number) => FoldStep<State>,
  options: WalkOptions = {},
): State {
  const childCursor = options.includeRelated ? relatedChildCursor : syntaxChildCursor;
  const progress: FoldProgress<State> = {
    result: initial,
    tasks: pushStack({ kind: 'node', node: root, depth: 0 }),
    seen: options.includeRelated ? PersistentSet<AstNode>() : null,
  };
  return loop<FoldProgress<State>, State>(progress, (state) => {
    const stack = state.tasks;
    if (!stack) {
      return done(state.result);
    }
    const task = stack.value;
    const remaining = stack.next;
    if (task.kind === 'children') {
      const cursor = task.cursor;
      return cursor
        ? again({
            ...state,
            tasks: pushStack<Task>(
              { kind: 'node', node: cursor.node, depth: task.depth },
              pushStack<Task>(
                { kind: 'children', cursor: cursor.tail(), depth: task.depth },
                remaining,
              ),
            ),
          })
        : again({ ...state, tasks: remaining });
    }
    if (state.seen?.has(task.node)) {
      return again({ ...state, tasks: remaining });
    }
    const result = reduce(state.result, task.node, task.depth);
    if (result.control === 'stop') {
      return done(result.state);
    }
    return again({
      result: result.state,
      seen: state.seen?.add(task.node) ?? null,
      tasks:
        result.control === 'skip'
          ? remaining
          : pushStack<Task>(
              {
                kind: 'children',
                cursor: childCursor(task.node),
                depth: task.depth + 1,
              },
              remaining,
            ),
    });
  });
}
export function walk(
  root: AstNode,
  visit: (node: AstNode, depth: number) => WalkControl,
  options: WalkOptions = {},
): void {
  foldAst(
    root,
    undefined,
    (_previous, node, depth) => ({ state: undefined, control: visit(node, depth) }),
    options,
  );
}
function hasKind<K extends AstNode['kind']>(
  node: AstNode,
  kind: K,
): node is Extract<AstNode, { readonly kind: K }> {
  return node.kind === kind;
}
export function findAll<K extends AstNode['kind']>(
  root: AstNode,
  kind: K,
  options: WalkOptions = {},
): readonly Extract<AstNode, { readonly kind: K }>[] {
  return foldAst(
    root,
    List<Extract<AstNode, { readonly kind: K }>>(),
    (nodes, node) => ({
      state: hasKind(node, kind) ? nodes.push(node) : nodes,
    }),
    options,
  ).toArray();
}
