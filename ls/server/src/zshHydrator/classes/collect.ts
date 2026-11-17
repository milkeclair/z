import { castDraft } from 'immer';
import { appendItems, makeMap, produce, setEntry } from '../../util/collections';
import { again, done, loop } from '../../util/loop';
import { pushStack, type Stack } from '../../util/stack';
import type { FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import { foldAst } from '../../zshParser/ast';
import { literalWord } from '../../zshParser/ast/word/literal';
import type { SourceRange } from '../../zshParser/lexer';
import type {
  ClassDefinition,
  ClassDefinitionScopeLocation,
  ClassInformation,
  ClassScopeLocation,
} from './types';

type Member = {
  readonly node: SimpleCommandNode;
  readonly information: Extract<ClassInformation, { kind: 'classAttribute' | 'classMethod' }>;
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
  readonly captures: ReadonlyMap<FunctionDefinitionNode | undefined, Capture>;
  readonly information: ReadonlyMap<number, ClassInformation | null>;
};

type ClassDirective = {
  readonly command: SimpleCommandNode;
  readonly name: string;
  readonly args: readonly (string | null)[];
  readonly depth: number;
  readonly scope: FunctionDefinitionNode | undefined;
};

/** 実行時に予約した名前を、静的なクラスの識別子から除外する。 */
function identifier(value: string | null | undefined): value is string {
  if (!value || value.startsWith('z_cls_')) return false;

  return [...value].every((char, index) => {
    const letter = (char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z');
    const digit = index > 0 && char >= '0' && char <= '9';

    return char === '_' || letter || digit;
  });
}

/** 以前のASTを付加情報に保持しないよう、所有関係を位置で記録する。 */
function scopeLocation(scope: FunctionDefinitionNode | undefined): ClassDefinitionScopeLocation {
  return scope ? { kind: 'function', offset: scope.range.start.offset } : { kind: 'file' };
}

/** 以前の状態を変更せず、1つの構文スコープの収集状態を置き換える。 */
function withCapture(
  state: State,
  scope: FunctionDefinitionNode | undefined,
  capture: Capture | null,
): State {
  const captures = produce(state.captures, (draft) => {
    if (capture) {
      draft.set(castDraft(scope), castDraft(capture));
    } else {
      draft.delete(castDraft(scope));
    }
  });

  return { ...state, captures };
}

/** 宣言形式にかかわらず、元の状態を変えない共通の遷移でメンバーを追加する。 */
function withMember(
  state: State,
  scope: FunctionDefinitionNode | undefined,
  definition: Definition,
  member: Member,
): State {
  return withCapture(state, scope, {
    kind: 'definition',
    definition: {
      ...definition,
      members: appendItems(definition.members, member),
    },
  });
}

/** 編集中に終了マーカーが欠けた場合も、本体のソース位置を保持する。 */
function blockMethodFromCapture(
  capture: Extract<Capture, { kind: 'method' }>,
  end: SourceRange,
  closed: boolean,
): Member {
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

/** クラス定義とメンバーの意味情報をまとめて確定する。 */
function finishDefinition(
  state: State,
  scope: FunctionDefinitionNode | undefined,
  capture: Capture,
  end: SourceRange,
  status: ClassDefinition['state'],
): State {
  const definition = capture.definition;
  const members =
    capture.kind === 'method'
      ? appendItems(definition.members, blockMethodFromCapture(capture, end, false))
      : definition.members;
  const information = produce(state.information, (draft) => {
    draft.set(definition.node.range.start.offset, {
      kind: 'classDefinition',
      name: definition.name,
      scope: scopeLocation(scope),
      state: status,
      range: { start: definition.node.range.start, end: end.end },
    });

    for (const member of members) {
      draft.set(member.node.range.start.offset, member.information);
    }
  });

  return { ...withCapture(state, scope, null), information };
}

/** 引数を実行せず、通常の構文から静的な宣言を1つ読む。 */
function readClassDirective(
  command: SimpleCommandNode,
  depth: number,
  scope: FunctionDefinitionNode | undefined,
): ClassDirective | null {
  const external = command.precommandModifiers.some(
    (modifier) => modifier.type === 'builtin' || modifier.type === 'command',
  );
  if (external) return null;

  const name = command.commandName && literalWord(command.commandName.word);
  if (!name || !name.startsWith('z.cls.')) return null;

  const names = [
    'z.cls.draw',
    'z.cls.attr',
    'z.cls.fn',
    'z.cls.fn.done',
    'z.cls.drew',
    'z.cls.abort',
    'z.cls.new',
  ];
  if (!names.includes(name)) return null;

  return { command, name, args: command.arguments.map((word) => literalWord(word)), depth, scope };
}

/** 通常の関数または収集中のメソッドのスコープに、実体の束縛を記録する。 */
function declareInstance(
  directive: ClassDirective,
  capture: Capture | undefined,
  state: State,
): State {
  const [className, name] = directive.args;
  if (directive.args.length !== 2 || !identifier(className) || !identifier(name)) return state;

  const scope: ClassScopeLocation =
    capture?.kind === 'method'
      ? { kind: 'classMethod', offset: capture.node.range.start.offset }
      : scopeLocation(directive.scope);

  return {
    ...state,
    information: setEntry(state.information, directive.command.range.start.offset, {
      kind: 'classInstance',
      name,
      className,
      scope,
    }),
  };
}

/** メソッド開始時と同じ構文の深さにある終了マーカーだけを処理する。 */
function applyMethodDirective(
  directive: ClassDirective,
  capture: Extract<Capture, { kind: 'method' }>,
  state: State,
): State {
  if (directive.depth !== capture.depth) return state;

  if (directive.name === 'z.cls.fn.done' && directive.args.length === 0) {
    return withMember(
      state,
      directive.scope,
      capture.definition,
      blockMethodFromCapture(capture, directive.command.range, true),
    );
  }

  if (directive.name === 'z.cls.abort' || directive.name === 'z.cls.drew') {
    return finishDefinition(state, directive.scope, capture, directive.command.range, 'aborted');
  }

  return state;
}

/** クラス内で最初に現れた有効な属性宣言を保持する。 */
function declareAttribute(directive: ClassDirective, definition: Definition, state: State): State {
  const name = directive.args[0];
  if (directive.args.length !== 2 || !identifier(name)) return state;

  const duplicate = definition.members.some(
    (member) => member.information.kind === 'classAttribute' && member.information.name === name,
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

/** 本体の収集を開始するか、引数で指定した本体の元の単語範囲を保持する。 */
function declareMethod(
  directive: ClassDirective,
  capture: Extract<Capture, { kind: 'definition' }>,
  state: State,
): State {
  const [name] = directive.args;
  if (directive.args.length < 1 || directive.args.length > 2 || !identifier(name)) return state;

  const definition = capture.definition;
  const duplicate = definition.members.some(
    (member) => member.information.kind === 'classMethod' && member.information.name === name,
  );
  if (duplicate) {
    return directive.args.length === 1
      ? finishDefinition(state, directive.scope, capture, directive.command.range, 'aborted')
      : state;
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

/** 定義中のクラスに、メンバー登録または公開の状態遷移を適用する。 */
function applyDefinitionDirective(
  directive: ClassDirective,
  capture: Extract<Capture, { kind: 'definition' }>,
  state: State,
): State {
  switch (directive.name) {
    case 'z.cls.attr':
      return declareAttribute(directive, capture.definition, state);
    case 'z.cls.fn':
      return declareMethod(directive, capture, state);
    case 'z.cls.drew':
      return directive.args.length === 0
        ? finishDefinition(state, directive.scope, capture, directive.command.range, 'published')
        : state;
    case 'z.cls.abort':
      return finishDefinition(state, directive.scope, capture, directive.command.range, 'aborted');
    default:
      return state;
  }
}

/** 現在の構文スコープの収集状態に応じて宣言を処理する。 */
function collectCommand(
  command: SimpleCommandNode,
  depth: number,
  scope: FunctionDefinitionNode | undefined,
  state: State,
): State {
  const directive = readClassDirective(command, depth, scope);
  if (!directive) return state;

  const capture = state.captures.get(scope);
  if (directive.name === 'z.cls.new') return declareInstance(directive, capture, state);
  if (capture?.kind === 'method') return applyMethodDirective(directive, capture, state);

  if (
    directive.name === 'z.cls.draw' &&
    directive.args.length === 1 &&
    identifier(directive.args[0]) &&
    !capture
  ) {
    return withCapture(state, scope, {
      kind: 'definition',
      definition: { node: command, name: directive.args[0], members: [] },
    });
  }

  return capture ? applyDefinitionDirective(directive, capture, state) : state;
}

type FunctionScope = {
  readonly node: FunctionDefinitionNode;
  readonly depth: number;
};
type CollectionProgress = {
  readonly collected: State;
  readonly functionScopes: Stack<FunctionScope> | null;
};

/** 通常の関数スコープごとに独立して、構文上のコマンドからクラス宣言を解釈する。 */
export function collectClassInformation(
  ast: FileNode,
): ReadonlyMap<number, ClassInformation | null> {
  const initial: CollectionProgress = {
    collected: { captures: makeMap(), information: makeMap() },
    functionScopes: null,
  };
  const progress = foldAst(ast, initial, (previous, node, depth) => {
    const active = loop<Stack<FunctionScope> | null, Stack<FunctionScope> | null>(
      previous.functionScopes,
      (scopes) => (scopes && scopes.value.depth >= depth ? again(scopes.next) : done(scopes)),
    );
    const functionScopes =
      node.kind === 'functionDefinition' ? pushStack({ node, depth }, active) : active;

    if (node.kind !== 'simpleCommand') {
      return { state: { ...previous, functionScopes } };
    }

    const collected =
      'hydration' in node
        ? {
            ...previous.collected,
            information: setEntry(previous.collected.information, node.range.start.offset, null),
          }
        : previous.collected;

    return {
      state: {
        collected: collectCommand(node, depth, functionScopes?.value.node, collected),
        functionScopes,
      },
    };
  });

  return [...progress.collected.captures].reduce((state, [scope, capture]) => {
    const end = scope?.range.end ?? ast.range.end;

    return finishDefinition(state, scope, capture, { start: end, end }, 'incomplete');
  }, progress.collected).information;
}
