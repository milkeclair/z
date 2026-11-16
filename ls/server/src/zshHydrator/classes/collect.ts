import type { FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import { walk } from '../../zshParser/ast';
import { literalWord } from '../../zshParser/ast/word/literal';
import type { SourceRange } from '../../zshParser/lexer';
import type { ClassDefinition, ClassInformation, ClassScopeLocation } from './types';

type Member = {
  readonly node: SimpleCommandNode;
  readonly information: ClassInformation;
};
type Definition = {
  readonly node: SimpleCommandNode;
  readonly name: string;
  readonly members: readonly Member[];
};
type Capture =
  | {
      readonly kind: 'definition';
      readonly definition: Definition;
    }
  | {
      readonly kind: 'method';
      readonly definition: Definition;
      readonly node: SimpleCommandNode;
      readonly name: string;
      readonly depth: number;
    };
type State = {
  readonly scopes: ReadonlyMap<FunctionDefinitionNode | undefined, Capture>;
  readonly information: ReadonlyMap<number, ClassInformation | null>;
};

type ClassDirective = {
  readonly command: SimpleCommandNode;
  readonly name: string;
  readonly args: readonly (string | null)[];
  readonly depth: number;
  readonly scope: FunctionDefinitionNode | undefined;
};

/** Keep runtime-reserved names outside statically declared class symbols. */
function identifier(value: string | null | undefined): value is string {
  if (!value || value.startsWith('z_cls_')) return false;

  return [...value].every((char, index) => {
    const letter = char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z';
    const digit = index > 0 && char >= '0' && char <= '9';

    return char === '_' || letter || digit;
  });
}

/** Store ownership by position so syntax attachments never retain an earlier AST. */
function scopeLocation(scope: FunctionDefinitionNode | undefined): ClassScopeLocation {
  return scope ? { kind: 'function', offset: scope.range.start.offset } : { kind: 'file' };
}

/** Replace one lexical capture without changing previous states. */
function withCapture(state: State, scope: FunctionDefinitionNode | undefined, capture: Capture | null): State {
  const scopes = new Map(state.scopes);

  if (capture) {
    scopes.set(scope, capture);
  } else {
    scopes.delete(scope);
  }

  return { ...state, scopes };
}

/** Add a member through the same immutable transition for every declaration form. */
function withMember(state: State, scope: FunctionDefinitionNode | undefined,
  definition: Definition, member: Member): State {
  return withCapture(state, scope, {
    kind: 'definition',
    definition: {
      ...definition,
      members: [...definition.members, member],
    },
  });
}

/** Keep block source positions even when editing leaves its end marker absent. */
function blockMethod(capture: Extract<Capture, { kind: 'method' }>, end: SourceRange, closed: boolean): Member {
  return {
    node: capture.node,
    information: {
      kind: 'classMethod',
      name: capture.name,
      classOffset: capture.definition.node.range.start.offset,
      body: {
        kind: 'block',
        range: { start: capture.node.range.end, end: end.start },
        end: closed ? end : null,
      },
    },
  };
}

/** Publish the complete definition and member meaning together. */
function finish(state: State, scope: FunctionDefinitionNode | undefined, capture: Capture,
  end: SourceRange, status: ClassDefinition['state']): State {
  const definition = capture.definition;
  const members = capture.kind === 'method'
    ? [...definition.members, blockMethod(capture, end, false)]
    : definition.members;
  const information = new Map(state.information);

  information.set(definition.node.range.start.offset, {
    kind: 'classDefinition',
    name: definition.name,
    scope: scopeLocation(scope),
    state: status,
    range: { start: definition.node.range.start, end: end.end },
  });

  for (const member of members) {
    information.set(member.node.range.start.offset, member.information);
  }

  return { ...withCapture(state, scope, null), information };
}

/** Read one literal directive from native syntax without executing its arguments. */
function classDirective(command: SimpleCommandNode, depth: number,
  scope: FunctionDefinitionNode | undefined): ClassDirective | null {
  const external = command.precommandModifiers.some(
    modifier => modifier.type === 'builtin' || modifier.type === 'command',
  );
  if (external) return null;

  const name = command.commandName && literalWord(command.commandName.word);
  if (!name || !name.startsWith('z.cls.')) return null;

  const names = ['z.cls.draw', 'z.cls.attr', 'z.cls.fn', 'z.cls.fn.done',
    'z.cls.drew', 'z.cls.abort', 'z.cls.new'];
  if (!names.includes(name)) return null;

  return { command, name, args: command.arguments.map(word => literalWord(word)), depth, scope };
}

/** Record a binding in its native function or captured method scope. */
function instanceDeclaration(directive: ClassDirective, capture: Capture | undefined, state: State): State {
  const [className, name] = directive.args;
  if (directive.args.length !== 2 || !identifier(className) || !identifier(name)) return state;

  const information = new Map(state.information);
  const scope: ClassScopeLocation = capture?.kind === 'method'
    ? { kind: 'classMethod', offset: capture.node.range.start.offset }
    : scopeLocation(directive.scope);

  information.set(directive.command.range.start.offset, {
    kind: 'classInstance',
    name,
    className,
    scope,
  });

  return { ...state, information };
}

/** Close only markers at the method's original syntax depth. */
function methodEnd(directive: ClassDirective, capture: Extract<Capture, { kind: 'method' }>, state: State): State {
  if (directive.depth !== capture.depth) return state;

  if (directive.name === 'z.cls.fn.done' && directive.args.length === 0) {
    return withMember(state, directive.scope, capture.definition, blockMethod(capture, directive.command.range, true));
  }

  if (directive.name === 'z.cls.abort' || directive.name === 'z.cls.drew') {
    return finish(state, directive.scope, capture, directive.command.range, 'aborted');
  }

  return state;
}

/** Retain the first valid attribute declaration in a definition. */
function attributeDeclaration(directive: ClassDirective, definition: Definition, state: State): State {
  const name = directive.args[0];
  if (directive.args.length !== 2 || !identifier(name)) return state;

  const duplicate = definition.members.some(
    member => member.information.kind === 'classAttribute' && member.information.name === name,
  );
  if (duplicate) return state;

  return withMember(state, directive.scope, definition, {
    node: directive.command,
    information: {
      kind: 'classAttribute',
      name,
      classOffset: definition.node.range.start.offset,
    },
  });
}

/** Start a block capture or retain an inline body's original word range. */
function methodDeclaration(directive: ClassDirective, capture: Capture, state: State): State {
  const [name] = directive.args;
  if (directive.args.length < 1 || directive.args.length > 2 || !identifier(name)) return state;

  const definition = capture.definition;
  const duplicate = definition.members.some(
    member => member.information.kind === 'classMethod' && member.information.name === name,
  );
  if (duplicate) {
    return directive.args.length === 1 ? finish(state, directive.scope, capture, directive.command.range, 'aborted') : state;
  }

  if (directive.args.length === 1) {
    return withCapture(state, directive.scope, {
      kind: 'method',
      definition,
      node: directive.command,
      name,
      depth: directive.depth,
    });
  }

  return withMember(state, directive.scope, definition, {
    node: directive.command,
    information: {
      kind: 'classMethod',
      name,
      classOffset: definition.node.range.start.offset,
      body: { kind: 'inline', range: directive.command.arguments[1].range },
    },
  });
}

/** Apply the member or publication transition for an open definition. */
function definitionDeclaration(directive: ClassDirective, capture: Capture, state: State): State {
  switch (directive.name) {
    case 'z.cls.attr':
      return attributeDeclaration(directive, capture.definition, state);
    case 'z.cls.fn':
      return methodDeclaration(directive, capture, state);
    case 'z.cls.drew':
      return directive.args.length === 0
        ? finish(state, directive.scope, capture, directive.command.range, 'published')
        : state;
    case 'z.cls.abort':
      return finish(state, directive.scope, capture, directive.command.range, 'aborted');
    default:
      return state;
  }
}

/** Route a directive through its current lexical capture state. */
function declaration(command: SimpleCommandNode, depth: number,
  scope: FunctionDefinitionNode | undefined, state: State): State {
  const directive = classDirective(command, depth, scope);
  if (!directive) return state;

  const capture = state.scopes.get(scope);
  if (directive.name === 'z.cls.new') return instanceDeclaration(directive, capture, state);
  if (capture?.kind === 'method') return methodEnd(directive, capture, state);

  if (directive.name === 'z.cls.draw' && directive.args.length === 1 && identifier(directive.args[0]) && !capture) {
    return withCapture(state, scope, {
      kind: 'definition',
      definition: { node: command, name: directive.args[0], members: [] },
    });
  }

  return capture ? definitionDeclaration(directive, capture, state) : state;
}

/** Interpret class directives from syntax commands, independently in each native function scope. */
export function collectClassInformation(ast: FileNode): ReadonlyMap<number, ClassInformation | null> {
  let state: State = { scopes: new Map(), information: new Map() };
  const scopes: { readonly node: FunctionDefinitionNode; readonly depth: number }[] = [];

  walk(ast, (node, depth) => {
    while (scopes.length && scopes[scopes.length - 1].depth >= depth) {
      scopes.pop();
    }

    if (node.kind === 'functionDefinition') {
      scopes.push({ node, depth });
    }

    if (node.kind !== 'simpleCommand') return;

    if ('hydration' in node) {
      const information = new Map(state.information);
      information.set(node.range.start.offset, null);
      state = { ...state, information };
    }

    state = declaration(node, depth, scopes.at(-1)?.node, state);
  });

  for (const [scope, capture] of state.scopes) {
    const end = scope?.range.end ?? ast.range.end;
    state = finish(state, scope, capture, { start: end, end }, 'incomplete');
  }

  return state.information;
}
