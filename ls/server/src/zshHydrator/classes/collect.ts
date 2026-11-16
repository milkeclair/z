import type { FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import { walk } from '../../zshParser/ast';
import { literalWord } from '../../zshParser/ast/word/literal';
import type { SourceRange } from '../../zshParser/lexer';
import type { ClassInformation, ClassScopeLocation } from './types';

type Member = { readonly node: SimpleCommandNode; readonly information: ClassInformation };
type Definition = { readonly node: SimpleCommandNode; readonly name: string; readonly members: readonly Member[] };
type Capture =
  | { readonly kind: 'definition'; readonly definition: Definition }
  | { readonly kind: 'method'; readonly definition: Definition; readonly node: SimpleCommandNode; readonly name: string; readonly depth: number };
type State = {
  readonly scopes: ReadonlyMap<FunctionDefinitionNode | undefined, Capture>;
  readonly information: ReadonlyMap<number, ClassInformation | null>;
};

/** Keep runtime-reserved names outside statically declared class symbols. */
function identifier(value: string | null | undefined): value is string {
  return value !== null && value !== undefined && value.length > 0 &&
    [...value].every((char, index) => char === '_' || char >= 'a' && char <= 'z' ||
      char >= 'A' && char <= 'Z' || index > 0 && char >= '0' && char <= '9') &&
    !value.startsWith('z_cls_') && !value.startsWith('__z_cls_');
}
/** Store ownership by position so syntax attachments never retain an earlier AST. */
function scopeLocation(scope: FunctionDefinitionNode | undefined): ClassScopeLocation {
  return scope ? { kind: 'function', offset: scope.range.start.offset } : { kind: 'file' };
}
/** Replace one lexical capture without changing previous states. */
function withCapture(state: State, scope: FunctionDefinitionNode | undefined, capture: Capture | null): State {
  const scopes = new Map(state.scopes);
  if (capture) scopes.set(scope, capture);
  else scopes.delete(scope);
  return { ...state, scopes };
}
/** Keep block source positions even when editing leaves its end marker absent. */
function method(capture: Extract<Capture, { kind: 'method' }>, end: SourceRange, closed: boolean): Member {
  return { node: capture.node, information: { kind: 'classMethod', name: capture.name,
    classOffset: capture.definition.node.range.start.offset,
    body: { kind: 'block', range: { start: capture.node.range.end, end: end.start }, end: closed ? end : null } } };
}
/** Publish the complete definition and member meaning together. */
function finish(state: State, scope: FunctionDefinitionNode | undefined, capture: Capture,
  end: SourceRange, status: 'published' | 'aborted' | 'incomplete'): State {
  const definition = capture.definition;
  const members = capture.kind === 'method' ? [...definition.members, method(capture, end, false)] : definition.members;
  const information = new Map(state.information);
  information.set(definition.node.range.start.offset, { kind: 'classDefinition', name: definition.name,
    scope: scopeLocation(scope), state: status, range: { start: definition.node.range.start, end: end.end } });
  for (const member of members) information.set(member.node.range.start.offset, member.information);
  return { ...withCapture(state, scope, null), information };
}
/** Interpret only literal directive commands in the current native function scope. */
function declaration(command: SimpleCommandNode, depth: number, scope: FunctionDefinitionNode | undefined, state: State): State {
  if (command.precommandModifiers.some(modifier => modifier.type === 'builtin' || modifier.type === 'command')) return state;
  const name = command.commandName && literalWord(command.commandName.word);
  if (!name || !name.startsWith('z.cls.')) return state;
  if (!['z.cls.draw', 'z.cls.attr', 'z.cls.fn', 'z.cls.fn.done', 'z.cls.drew', 'z.cls.abort', 'z.cls.new'].includes(name)) return state;
  const args = command.arguments.map(word => literalWord(word));
  const capture = state.scopes.get(scope);
  if (name === 'z.cls.new' && args.length === 2 && identifier(args[0]) && identifier(args[1])) {
    const information = new Map(state.information);
    information.set(command.range.start.offset, { kind: 'classInstance', name: args[1], className: args[0],
      scope: capture?.kind === 'method' ? { kind: 'classMethod', offset: capture.node.range.start.offset } : scopeLocation(scope) });
    return { ...state, information };
  }
  if (capture?.kind === 'method') {
    if (depth !== capture.depth) return state;
    if (name === 'z.cls.fn.done' && args.length === 0) {
      return withCapture(state, scope, { kind: 'definition', definition: { ...capture.definition,
        members: [...capture.definition.members, method(capture, command.range, true)] } });
    }
    return name === 'z.cls.abort' || name === 'z.cls.drew' ? finish(state, scope, capture, command.range, 'aborted') : state;
  }
  if (name === 'z.cls.draw' && args.length === 1 && identifier(args[0]) && !capture) {
    return withCapture(state, scope, { kind: 'definition', definition: { node: command, name: args[0], members: [] } });
  }
  if (!capture) return state;
  const definition = capture.definition;
  if (name === 'z.cls.attr' && args.length === 2 && identifier(args[0])) {
    if (definition.members.some(m => m.information.kind === 'classAttribute' && m.information.name === args[0])) return state;
    return withCapture(state, scope, { kind: 'definition', definition: { ...definition,
      members: [...definition.members, { node: command, information: { kind: 'classAttribute', name: args[0],
        classOffset: definition.node.range.start.offset } }] } });
  }
  if (name === 'z.cls.fn' && args.length >= 1 && args.length <= 2 && identifier(args[0])) {
    if (definition.members.some(m => m.information.kind === 'classMethod' && m.information.name === args[0])) {
      return args.length === 1 ? finish(state, scope, capture, command.range, 'aborted') : state;
    }
    if (args.length === 1) return withCapture(state, scope, { kind: 'method', definition, node: command, name: args[0], depth });
    return withCapture(state, scope, { kind: 'definition', definition: { ...definition,
      members: [...definition.members, { node: command, information: { kind: 'classMethod', name: args[0],
        classOffset: definition.node.range.start.offset,
        body: { kind: 'inline', range: command.arguments[1].range } } }] } });
  }
  if (name === 'z.cls.drew' && args.length === 0) return finish(state, scope, capture, command.range, 'published');
  return name === 'z.cls.abort' ? finish(state, scope, capture, command.range, 'aborted') : state;
}

/** Interpret class directives from syntax commands, independently in each native function scope. */
export function collectClassInformation(ast: FileNode): ReadonlyMap<number, ClassInformation | null> {
  let state: State = { scopes: new Map(), information: new Map() };
  const scopes: { readonly node: FunctionDefinitionNode; readonly depth: number }[] = [];
  walk(ast, (node, depth) => {
    while (scopes.length && scopes[scopes.length - 1].depth >= depth) scopes.pop();
    if (node.kind === 'functionDefinition') scopes.push({ node, depth });
    if (node.kind === 'simpleCommand') {
      if ('hydration' in node) {
        const information = new Map(state.information);
        information.set(node.range.start.offset, null);
        state = { ...state, information };
      }
      state = declaration(node, depth, scopes.at(-1)?.node, state);
    }
  });
  for (const [scope, capture] of state.scopes) {
    const end = scope?.range.end ?? ast.range.end;
    state = finish(state, scope, capture, { start: end, end }, 'incomplete');
  }
  return state.information;
}
