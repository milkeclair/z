import { castDraft } from 'immer';
import { produce } from '../../../util/collections';
import type { AstNode } from '..';
import { again, done, loop } from '../../../util/loop';
import { pushStack, type Stack } from '../../../util/stack';
import { relatedChildCursor, syntaxChildCursor, type ChildCursor } from './children';

export type WalkControl = void | 'skip' | 'stop';

export type WalkOptions = {
  readonly includeRelated?: boolean;
};

export type TraversalFrame = {
  readonly node: AstNode;
  readonly children: ChildCursor | null;
  readonly depth: number;
};

type Task =
  | {
      readonly kind: 'node';
      readonly node: AstNode;
      readonly depth: number;
    }
  | {
      readonly kind: 'children';
      readonly cursor: ChildCursor | null;
      readonly depth: number;
    };

export type FoldStep<State> = {
  readonly state: State;
  readonly control?: WalkControl;
};

type FoldProgress<State> = {
  readonly result: State;
  readonly tasks: Stack<Task> | null;
};

export function foldAst<State>(
  root: AstNode,
  initial: State,
  reduce: (state: State, node: AstNode, depth: number) => FoldStep<State>,
  options: WalkOptions = {},
): State {
  if (!options.includeRelated) {
    return foldNodes(root, initial, reduce, syntaxChildCursor);
  }

  // ASTをキーとして保持し、重複の判定でノード自体をdraftへ変換しない。
  const result = produce({ seen: new Map<AstNode, true>(), read: () => initial }, (draft) => {
    const value = foldNodes(root, initial, reduce, relatedChildCursor, draft.seen);
    draft.read = () => value;
  });

  return result.read();
}

function foldNodes<State>(
  root: AstNode,
  initial: State,
  reduce: (state: State, node: AstNode, depth: number) => FoldStep<State>,
  childCursor: (node: AstNode) => ChildCursor | null,
  seen?: Map<AstNode, true>,
): State {
  const progress: FoldProgress<State> = {
    result: initial,
    tasks: pushStack({ kind: 'node', node: root, depth: 0 }),
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

    if (seen?.has(task.node)) {
      return again({ ...state, tasks: remaining });
    }

    const result = reduce(state.result, task.node, task.depth);

    if (result.control === 'stop') {
      return done(result.state);
    }

    seen?.set(task.node, true);

    return again({
      result: result.state,
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
): node is Extract<
  AstNode,
  {
    readonly kind: K;
  }
> {
  return node.kind === kind;
}

export function findAll<K extends AstNode['kind']>(
  root: AstNode,
  kind: K,
  options: WalkOptions = {},
): readonly Extract<
  AstNode,
  {
    readonly kind: K;
  }
>[] {
  return produce<readonly Extract<AstNode, { readonly kind: K }>[]>([], (nodes) => {
    walk(
      root,
      (node) => {
        if (hasKind(node, kind)) nodes.push(castDraft(node));
      },
      options,
    );
  });
}
