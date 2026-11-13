import type { AstNode, FileNode } from '..';
import { withRelatedChildren } from './index';

function ofKind<K extends AstNode['kind']>(node: AstNode, kind: K): node is Extract<AstNode, { readonly kind: K }> {
  return node.kind === kind;
}

/** Rebuild changed paths once, preserving aliases across syntax and related edges. */
export function mapAst(file: FileNode, transform: (node: AstNode) => AstNode): FileNode {
  const mapped = new WeakMap<AstNode, AstNode>();
  const active = new WeakSet<AstNode>();
  const stack: { readonly node: AstNode; readonly children: Iterator<AstNode> }[] = [];
  const get = <K extends AstNode['kind']>(node: AstNode, kind: K): Extract<AstNode, { readonly kind: K }> => {
    const result = mapped.get(node) ?? node;
    if (!ofKind(result, kind)) throw new Error('AST transformation changed a node kind');
    return result;
  };
  const enter = (node: AstNode): void => {
    active.add(node);
    stack.push({ node, children: withRelatedChildren(node) });
  };
  enter(file);
  while (stack.length > 0) {
    const frame = stack[stack.length - 1];
    const child = frame.children.next();
    if (!child.done) {
      if (active.has(child.value)) throw new Error('Cyclic AST ownership');
      if (!mapped.has(child.value)) enter(child.value);
      continue;
    }
    let changed = false;
    for (const source of withRelatedChildren(frame.node)) if ((mapped.get(source) ?? source) !== source) { changed = true; break; }
    const node = changed ? rebuild(frame.node) : frame.node;
    const result = transform(node);
    if (result.kind !== node.kind) throw new Error('AST transformation changed a node kind');
    mapped.set(frame.node, result);
    active.delete(frame.node);
    stack.pop();
  }
  return get(file, 'file');

  function rebuild(node: AstNode): AstNode {
    switch (node.kind) {
      case 'file': return { ...node, body: get(node.body, 'list'), eof: get(node.eof, 'eof'), comments: node.comments.map((n) => get(n, 'comment')) };
      case 'list': return { ...node, items: node.items.map((n) => get(n, 'listItem')) };
      case 'listItem': return { ...node, sublist: get(node.sublist, node.sublist.kind), terminator: node.terminator ? get(node.terminator, 'terminator') : null };
      case 'sublist': return { ...node, first: get(node.first, 'pipeline'), rest: node.rest.map((n) => ({ operator: get(n.operator, 'logicalOperator'), pipeline: get(n.pipeline, 'pipeline') })) };
      case 'pipeline': return { ...node, timing: node.timing ? get(node.timing, 'pipelineTiming') : null,
        modifier: node.modifier ? get(node.modifier, 'pipelineModifier') : null, first: get(node.first, node.first.kind),
        rest: node.rest.map((n) => ({ operator: get(n.operator, 'pipelineOperator'), command: get(n.command, n.command.kind) })) };
      case 'simpleCommand': {
        const semantic = node.semantic;
        const nextSemantic = semantic.role === 'source' ? { ...semantic, source: { ...semantic.source, target: semantic.source.target ? get(semantic.source.target, 'word') : null } }
          : semantic.role === 'declaration' ? { ...semantic, declaration: { ...semantic.declaration,
            options: semantic.declaration.options.map((n) => get(n, 'option')),
            assignments: semantic.declaration.assignments.map((n) => get(n, 'assign')),
            names: semantic.declaration.names.map((n) => get(n, 'variableName')),
          } } : semantic;
        return { ...node, semantic: nextSemantic, precommandModifiers: node.precommandModifiers.map((n) => get(n, 'precommandModifier')),
          prefixAssignments: node.prefixAssignments.map((n) => get(n, 'assign')),
          commandName: node.commandName ? get(node.commandName, 'commandName') : null,
          arguments: node.arguments.map((n) => get(n, 'word')), redirects: node.redirects.map((n) => get(n, 'redirect')) };
      }
      case 'functionDefinition': return { ...node, options: node.options.map((n) => get(n, 'option')), names: node.names.map((n) => get(n, 'word')),
        body: get(node.body, node.body.kind), leadingDoc: node.leadingDoc ? get(node.leadingDoc, 'docBlock') : null,
        postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'groupCommand': return { ...node, body: get(node.body, 'list'), always: node.always ? get(node.always, 'alwaysClause') : null,
        postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'subshellCommand': return { ...node, body: get(node.body, 'list'), postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'alwaysClause': return { ...node, body: get(node.body, node.body.kind) };
      case 'ifCommand': return { ...node, branches: node.branches.map((n) => get(n, 'ifBranch')), elseBody: node.elseBody ? get(node.elseBody, 'list') : null,
        postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'ifBranch': return { ...node, condition: get(node.condition, 'list'), body: get(node.body, 'list') };
      case 'whileCommand':
      case 'untilCommand': return { ...node, condition: get(node.condition, 'list'), body: get(node.body, 'list'), postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'forCommand':
      case 'selectCommand':
      case 'foreachCommand': return { ...node, variables: node.variables.map((n) => get(n, 'word')), words: node.words?.map((n) => get(n, 'word')) ?? null,
        arithmetic: node.arithmetic ? get(node.arithmetic, 'arithmeticExpansion') : null, body: get(node.body, 'list'),
        postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'repeatCommand': return { ...node, count: node.count ? get(node.count, 'word') : null, body: get(node.body, 'list'), postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'caseCommand': return { ...node, subject: node.subject ? get(node.subject, 'word') : null, arms: node.arms.map((n) => get(n, 'caseArm')), postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'caseArm': return { ...node, patterns: node.patterns.map((n) => get(n, 'word')), body: get(node.body, 'list') };
      case 'opaqueCommand': return { ...node, postBodyRedirects: node.postBodyRedirects.map((n) => get(n, 'redirect')) };
      case 'precommandModifier': return { ...node, options: node.options.map((n) => get(n, 'option')) };
      case 'commandName': return { ...node, word: get(node.word, 'word') };
      case 'option': return { ...node, value: node.value ? get(node.value, 'word') : null };
      case 'assign': return { ...node, name: get(node.name, 'variableName'), subscript: node.subscript ? get(node.subscript, 'word') : null, value: node.value ? get(node.value, 'variableValue') : null };
      case 'variableValue': return { ...node, value: get(node.value, 'word') };
      case 'word': return { ...node, parts: node.parts.map((n) => get(n, n.kind)) };
      case 'variableReference': return { ...node, name: get(node.name, 'variableName') };
      case 'commandSubstitution':
      case 'processSubstitution': return { ...node, body: node.body ? get(node.body, 'list') : null };
      case 'redirect': return { ...node, target: node.target ? get(node.target, 'word') : null, hereDocument: node.hereDocument ? get(node.hereDocument, 'hereDocument') : null };
      case 'docBlock': return { ...node, comments: node.comments.map((n) => get(n, 'comment')) };
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
      case 'arithmeticExpansion': return node;
    }
    const exhaustive: never = node;
    return exhaustive;
  }
}
