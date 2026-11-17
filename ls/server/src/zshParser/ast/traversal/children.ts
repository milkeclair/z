import type { AstNode } from '..';

export function* syntaxChildren(node: AstNode): Generator<AstNode> {
  switch (node.kind) {
    case 'file':
      yield node.body;
      yield node.eof;
      return;
    case 'list':
      yield* node.items;
      return;
    case 'listItem':
      yield node.sublist;
      if (node.terminator) {
        yield node.terminator;
      }
      return;
    case 'sublist':
      yield node.first;
      for (const rest of node.rest) {
        yield rest.operator;
        yield rest.pipeline;
      }
      return;
    case 'pipeline':
      if (node.timing) {
        yield node.timing;
      }
      if (node.modifier) {
        yield node.modifier;
      }
      yield node.first;
      for (const rest of node.rest) {
        yield rest.operator;
        yield rest.command;
      }
      return;
    case 'simpleCommand':
      yield* node.precommandModifiers;
      yield* node.prefixAssignments;
      if (node.commandName) {
        yield node.commandName;
      }
      yield* node.arguments;
      yield* node.redirects;
      return;
    case 'functionDefinition':
      yield* node.options;
      yield* node.names;
      yield node.body;
      yield* node.postBodyRedirects;
      return;
    case 'groupCommand':
      yield node.body;
      if (node.always) {
        yield node.always;
      }
      yield* node.postBodyRedirects;
      return;
    case 'alwaysClause':
      yield node.body;
      return;
    case 'subshellCommand':
      yield node.body;
      yield* node.postBodyRedirects;
      return;
    case 'ifCommand':
      yield* node.branches;
      if (node.elseBody) {
        yield node.elseBody;
      }
      yield* node.postBodyRedirects;
      return;
    case 'ifBranch':
      yield node.condition;
      yield node.body;
      return;
    case 'whileCommand':
    case 'untilCommand':
      yield node.condition;
      yield node.body;
      yield* node.postBodyRedirects;
      return;
    case 'forCommand':
    case 'selectCommand':
    case 'foreachCommand':
      yield* node.variables;
      if (node.words) {
        yield* node.words;
      }
      if (node.arithmetic) {
        yield node.arithmetic;
      }
      yield node.body;
      yield* node.postBodyRedirects;
      return;
    case 'repeatCommand':
      if (node.count) {
        yield node.count;
      }
      yield node.body;
      yield* node.postBodyRedirects;
      return;
    case 'caseCommand':
      if (node.subject) {
        yield node.subject;
      }
      yield* node.arms;
      yield* node.postBodyRedirects;
      return;
    case 'caseArm':
      yield* node.patterns;
      yield node.body;
      return;
    case 'opaqueCommand':
      yield* node.postBodyRedirects;
      return;
    case 'precommandModifier':
      yield* node.options;
      return;
    case 'commandName':
      yield node.word;
      return;
    case 'option':
      if (node.value) {
        yield node.value;
      }
      return;
    case 'assign':
      yield node.name;
      if (node.subscript) {
        yield node.subscript;
      }
      if (node.value) {
        yield node.value;
      }
      return;
    case 'variableValue':
      yield node.value;
      return;
    case 'word':
      yield* node.parts;
      return;
    case 'variableReference':
      yield node.name;
      return;
    case 'processSubstitution':
    case 'commandSubstitution':
      if (node.body) {
        yield node.body;
      }
      return;
    case 'redirect':
      if (node.target) {
        yield node.target;
      }
      if (node.hereDocument) {
        yield node.hereDocument;
      }
      return;
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
  for (const child of syntaxChildren(node)) {
    visit(child);
  }
}

export function* withRelatedChildren(node: AstNode): Generator<AstNode> {
  yield* syntaxChildren(node);
  switch (node.kind) {
    case 'file':
      yield* node.comments;
      break;
    case 'functionDefinition':
      if (node.leadingDoc) {
        yield node.leadingDoc;
      }
      break;
    case 'docBlock':
      yield* node.comments;
      break;
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
