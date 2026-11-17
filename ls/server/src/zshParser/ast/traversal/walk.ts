import type { AstNode } from '..';
import { syntaxChildren, withRelatedChildren } from './children';

export type WalkControl = void | 'skip' | 'stop';

export type WalkOptions = { readonly includeRelated?: boolean };

export type TraversalFrame = {
  readonly node: AstNode;
  readonly next: Iterator<AstNode>;
  readonly depth: number;
};

export function walk(
  root: AstNode,
  visit: (node: AstNode, depth: number) => WalkControl,
  options: WalkOptions = {},
): void {
  const stack: TraversalFrame[] = [];
  const seen = options.includeRelated ? new WeakSet<AstNode>() : null;

  function enter(node: AstNode, depth: number): boolean {
    if (seen?.has(node)) {
      return true;
    }
    seen?.add(node);
    const action = visit(node, depth);
    if (action === 'stop') {
      return false;
    }
    if (action !== 'skip') {
      const next = options.includeRelated ? withRelatedChildren(node) : syntaxChildren(node);
      stack.push({ node, next, depth });
    }
    return true;
  }

  if (!enter(root, 0)) {
    return;
  }
  while (stack.length > 0) {
    const frame = stack[stack.length - 1];
    const child = frame.next.next();
    if (child.done) {
      stack.pop();
    } else if (!enter(child.value, frame.depth + 1)) {
      return;
    }
  }
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
  const found: Extract<AstNode, { readonly kind: K }>[] = [];
  walk(
    root,
    (node) => {
      if (hasKind(node, kind)) {
        found.push(node);
      }
    },
    options,
  );
  return found;
}
