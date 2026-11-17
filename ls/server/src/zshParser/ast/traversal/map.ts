import * as Immutable from 'immutable';
import type {
  AssignNode,
  AstNode,
  CaseCommandNode,
  FileNode,
  ForCommandNode,
  ForeachCommandNode,
  FunctionDefinitionNode,
  GroupCommandNode,
  IfCommandNode,
  PipelineNode,
  RedirectNode,
  SelectCommandNode,
  SimpleCommandNode,
  SimpleCommandSemantic,
} from '..';
import { again, done, loop } from '../../../util/loop';
import { pushStack, type Stack } from '../../../util/stack';
import { relatedChildCursor, someChild, type ChildCursor } from './children';

type NodeMap = Immutable.Map<AstNode, AstNode>;

type Frame = {
  readonly node: AstNode;
  readonly children: ChildCursor | null;
};

type Progress = {
  readonly mapped: NodeMap;
  readonly active: Immutable.Set<AstNode>;
  readonly frames: Stack<Frame> | null;
};

function ofKind<K extends AstNode['kind']>(
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

function getMappedNode<K extends AstNode['kind']>(
  mapped: NodeMap,
  node: AstNode,
  kind: K,
): Extract<
  AstNode,
  {
    readonly kind: K;
  }
> {
  const result = mapped.get(node) ?? node;

  if (!ofKind(result, kind)) {
    throw new Error('AST transformation changed a node kind');
  }

  return result;
}

/** 関連辺を含む共有ノードを1回だけ変換し、以前のASTを変更せずに参照関係を保つ。 */
export function mapAst(file: FileNode, transform: (node: AstNode) => AstNode): FileNode {
  const initial: Progress = {
    mapped: Immutable.Map(),
    active: Immutable.Set([file]),
    frames: pushStack({ node: file, children: relatedChildCursor(file) }),
  };

  return loop<Progress, FileNode>(initial, (state) => {
    const stack = state.frames;

    if (!stack) {
      return done(getMappedNode(state.mapped, file, 'file'));
    }

    const frame = stack.value;
    const child = frame.children;

    if (child) {
      if (state.active.has(child.node)) {
        throw new Error('Cyclic AST ownership');
      }

      const frames = pushStack({ ...frame, children: child.tail() }, stack.next);

      return state.mapped.has(child.node)
        ? again({ ...state, frames })
        : again({
            ...state,
            active: state.active.add(child.node),
            frames: pushStack(
              { node: child.node, children: relatedChildCursor(child.node) },
              frames,
            ),
          });
    }

    const changed = someChild(
      relatedChildCursor(frame.node),
      (source) => (state.mapped.get(source) ?? source) !== source,
    );
    const node = changed ? rebuildNode(frame.node, state.mapped) : frame.node;
    const result = transform(node);

    if (result.kind !== node.kind) {
      throw new Error('AST transformation changed a node kind');
    }

    return again({
      mapped: state.mapped.set(frame.node, result),
      active: state.active.delete(frame.node),
      frames: stack.next,
    });
  });
}

function rebuildPipeline(node: PipelineNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    timing: node.timing ? getMappedNode(mapped, node.timing, 'pipelineTiming') : null,
    modifier: node.modifier ? getMappedNode(mapped, node.modifier, 'pipelineModifier') : null,
    first: getMappedNode(mapped, node.first, node.first.kind),
    rest: node.rest.map((continuation) => ({
      operator: getMappedNode(mapped, continuation.operator, 'pipelineOperator'),
      command: getMappedNode(mapped, continuation.command, continuation.command.kind),
    })),
  };
}

function rebuildSemantic(semantic: SimpleCommandSemantic, mapped: NodeMap): SimpleCommandSemantic {
  if (semantic.role === 'source')
    return {
      ...semantic,
      source: {
        ...semantic.source,
        target: semantic.source.target
          ? getMappedNode(mapped, semantic.source.target, 'word')
          : null,
      },
    };
  if (semantic.role === 'declaration')
    return {
      ...semantic,
      declaration: {
        ...semantic.declaration,
        options: semantic.declaration.options.map((option) =>
          getMappedNode(mapped, option, 'option'),
        ),
        assignments: semantic.declaration.assignments.map((assignment) =>
          getMappedNode(mapped, assignment, 'assign'),
        ),
        names: semantic.declaration.names.map((variable) =>
          getMappedNode(mapped, variable, 'variableName'),
        ),
      },
    };
  return semantic;
}

function rebuildSimpleCommand(node: SimpleCommandNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    semantic: rebuildSemantic(node.semantic, mapped),
    precommandModifiers: node.precommandModifiers.map((modifier) =>
      getMappedNode(mapped, modifier, 'precommandModifier'),
    ),
    prefixAssignments: node.prefixAssignments.map((assignment) =>
      getMappedNode(mapped, assignment, 'assign'),
    ),
    commandName: node.commandName ? getMappedNode(mapped, node.commandName, 'commandName') : null,
    arguments: node.arguments.map((word) => getMappedNode(mapped, word, 'word')),
    redirects: node.redirects.map((redirect) => getMappedNode(mapped, redirect, 'redirect')),
  };
}

function rebuildFunctionDefinition(node: FunctionDefinitionNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    options: node.options.map((option) => getMappedNode(mapped, option, 'option')),
    names: node.names.map((word) => getMappedNode(mapped, word, 'word')),
    body: getMappedNode(mapped, node.body, node.body.kind),
    leadingDoc: node.leadingDoc ? getMappedNode(mapped, node.leadingDoc, 'docBlock') : null,
    postBodyRedirects: node.postBodyRedirects.map((redirect) =>
      getMappedNode(mapped, redirect, 'redirect'),
    ),
  };
}

function rebuildGroupCommand(node: GroupCommandNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    body: getMappedNode(mapped, node.body, 'list'),
    always: node.always ? getMappedNode(mapped, node.always, 'alwaysClause') : null,
    postBodyRedirects: node.postBodyRedirects.map((redirect) =>
      getMappedNode(mapped, redirect, 'redirect'),
    ),
  };
}

function rebuildIfCommand(node: IfCommandNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    branches: node.branches.map((branch) => getMappedNode(mapped, branch, 'ifBranch')),
    elseBody: node.elseBody ? getMappedNode(mapped, node.elseBody, 'list') : null,
    postBodyRedirects: node.postBodyRedirects.map((redirect) =>
      getMappedNode(mapped, redirect, 'redirect'),
    ),
  };
}

function rebuildIteration(
  node: ForCommandNode | SelectCommandNode | ForeachCommandNode,
  mapped: NodeMap,
): AstNode {
  return {
    ...node,
    variables: node.variables.map((word) => getMappedNode(mapped, word, 'word')),
    words: node.words?.map((word) => getMappedNode(mapped, word, 'word')) ?? null,
    arithmetic: node.arithmetic
      ? getMappedNode(mapped, node.arithmetic, 'arithmeticExpansion')
      : null,
    body: getMappedNode(mapped, node.body, 'list'),
    postBodyRedirects: node.postBodyRedirects.map((redirect) =>
      getMappedNode(mapped, redirect, 'redirect'),
    ),
  };
}

function rebuildCaseCommand(node: CaseCommandNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    subject: node.subject ? getMappedNode(mapped, node.subject, 'word') : null,
    arms: node.arms.map((arm) => getMappedNode(mapped, arm, 'caseArm')),
    postBodyRedirects: node.postBodyRedirects.map((redirect) =>
      getMappedNode(mapped, redirect, 'redirect'),
    ),
  };
}

function rebuildAssignment(node: AssignNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    name: getMappedNode(mapped, node.name, 'variableName'),
    subscript: node.subscript ? getMappedNode(mapped, node.subscript, 'word') : null,
    value: node.value ? getMappedNode(mapped, node.value, 'variableValue') : null,
  };
}

function rebuildRedirect(node: RedirectNode, mapped: NodeMap): AstNode {
  return {
    ...node,
    target: node.target ? getMappedNode(mapped, node.target, 'word') : null,
    hereDocument: node.hereDocument
      ? getMappedNode(mapped, node.hereDocument, 'hereDocument')
      : null,
  };
}

function rebuildNode(node: AstNode, mapped: NodeMap): AstNode {
  switch (node.kind) {
    case 'file':
      return {
        ...node,
        body: getMappedNode(mapped, node.body, 'list'),
        eof: getMappedNode(mapped, node.eof, 'eof'),
        comments: node.comments.map((comment) => getMappedNode(mapped, comment, 'comment')),
      };
    case 'list':
      return { ...node, items: node.items.map((item) => getMappedNode(mapped, item, 'listItem')) };
    case 'listItem':
      return {
        ...node,
        sublist: getMappedNode(mapped, node.sublist, node.sublist.kind),
        terminator: node.terminator ? getMappedNode(mapped, node.terminator, 'terminator') : null,
      };
    case 'sublist':
      return {
        ...node,
        first: getMappedNode(mapped, node.first, 'pipeline'),
        rest: node.rest.map((continuation) => ({
          operator: getMappedNode(mapped, continuation.operator, 'logicalOperator'),
          pipeline: getMappedNode(mapped, continuation.pipeline, 'pipeline'),
        })),
      };
    case 'pipeline':
      return rebuildPipeline(node, mapped);
    case 'simpleCommand':
      return rebuildSimpleCommand(node, mapped);
    case 'functionDefinition':
      return rebuildFunctionDefinition(node, mapped);
    case 'groupCommand':
      return rebuildGroupCommand(node, mapped);
    case 'subshellCommand':
      return {
        ...node,
        body: getMappedNode(mapped, node.body, 'list'),
        postBodyRedirects: node.postBodyRedirects.map((redirect) =>
          getMappedNode(mapped, redirect, 'redirect'),
        ),
      };
    case 'alwaysClause':
      return { ...node, body: getMappedNode(mapped, node.body, node.body.kind) };
    case 'ifCommand':
      return rebuildIfCommand(node, mapped);
    case 'ifBranch':
      return {
        ...node,
        condition: getMappedNode(mapped, node.condition, 'list'),
        body: getMappedNode(mapped, node.body, 'list'),
      };
    case 'whileCommand':
    case 'untilCommand':
      return {
        ...node,
        condition: getMappedNode(mapped, node.condition, 'list'),
        body: getMappedNode(mapped, node.body, 'list'),
        postBodyRedirects: node.postBodyRedirects.map((redirect) =>
          getMappedNode(mapped, redirect, 'redirect'),
        ),
      };
    case 'forCommand':
    case 'selectCommand':
    case 'foreachCommand':
      return rebuildIteration(node, mapped);
    case 'repeatCommand':
      return {
        ...node,
        count: node.count ? getMappedNode(mapped, node.count, 'word') : null,
        body: getMappedNode(mapped, node.body, 'list'),
        postBodyRedirects: node.postBodyRedirects.map((redirect) =>
          getMappedNode(mapped, redirect, 'redirect'),
        ),
      };
    case 'caseCommand':
      return rebuildCaseCommand(node, mapped);
    case 'caseArm':
      return {
        ...node,
        patterns: node.patterns.map((word) => getMappedNode(mapped, word, 'word')),
        body: getMappedNode(mapped, node.body, 'list'),
      };
    case 'opaqueCommand':
      return {
        ...node,
        postBodyRedirects: node.postBodyRedirects.map((redirect) =>
          getMappedNode(mapped, redirect, 'redirect'),
        ),
      };
    case 'precommandModifier':
      return {
        ...node,
        options: node.options.map((option) => getMappedNode(mapped, option, 'option')),
      };
    case 'commandName':
      return { ...node, word: getMappedNode(mapped, node.word, 'word') };
    case 'option':
      return { ...node, value: node.value ? getMappedNode(mapped, node.value, 'word') : null };
    case 'assign':
      return rebuildAssignment(node, mapped);
    case 'variableValue':
      return { ...node, value: getMappedNode(mapped, node.value, 'word') };
    case 'word':
      return { ...node, parts: node.parts.map((part) => getMappedNode(mapped, part, part.kind)) };
    case 'variableReference':
      return { ...node, name: getMappedNode(mapped, node.name, 'variableName') };
    case 'commandSubstitution':
    case 'processSubstitution':
      return { ...node, body: node.body ? getMappedNode(mapped, node.body, 'list') : null };
    case 'redirect':
      return rebuildRedirect(node, mapped);
    case 'docBlock':
      return {
        ...node,
        comments: node.comments.map((comment) => getMappedNode(mapped, comment, 'comment')),
      };
    case 'hereDocument':
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
      return node;
  }

  const exhaustive: never = node;

  return exhaustive;
}
