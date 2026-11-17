import type { FileNode, FunctionDefinitionNode, SimpleCommandNode } from '../../zshParser/ast';
import { walk } from '../../zshParser/ast';
import { literalWord } from '../../zshParser/ast/word/literal';
import type { SourceRange } from '../../zshParser/lexer';
import type { ClassDefinition, ClassDefinitionScopeLocation, ClassInformation, ClassScopeLocation } from './types';

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

/** 実行時に予約した名前を、静的なクラスの識別子から除外する。 */
function identifier(value: string | null | undefined): value is string {
  if (!value || value.startsWith('z_cls_')) return false;

  return [...value].every((char, index) => {
    const letter = char >= 'a' && char <= 'z' || char >= 'A' && char <= 'Z';
    const digit = index > 0 && char >= '0' && char <= '9';

    return char === '_' || letter || digit;
  });
}

/** 以前のASTを付加情報に保持しないよう、所有関係を位置で記録する。 */
function scopeLocation(scope: FunctionDefinitionNode | undefined): ClassDefinitionScopeLocation {
  return scope ? { kind: 'function', offset: scope.range.start.offset } : { kind: 'file' };
}

/** 以前の状態を変更せず、1つの構文スコープの収集状態を置き換える。 */
function withCapture(state: State, scope: FunctionDefinitionNode | undefined, capture: Capture | null): State {
  const scopes = new Map(state.scopes);

  if (capture) {
    scopes.set(scope, capture);
  } else {
    scopes.delete(scope);
  }

  return { ...state, scopes };
}

/** 宣言形式にかかわらず、元の状態を変えない共通の遷移でメンバーを追加する。 */
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

/** 編集中に終了マーカーが欠けた場合も、本体のソース位置を保持する。 */
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

/** クラス定義とメンバーの意味情報をまとめて確定する。 */
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

/** 引数を実行せず、通常の構文から静的な宣言を1つ読む。 */
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

/** 通常の関数または収集中のメソッドのスコープに、実体の束縛を記録する。 */
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

/** メソッド開始時と同じ構文の深さにある終了マーカーだけを処理する。 */
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

/** クラス内で最初に現れた有効な属性宣言を保持する。 */
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

/** 本体の収集を開始するか、引数で指定した本体の元の単語範囲を保持する。 */
function methodDeclaration(directive: ClassDirective, capture: Extract<Capture, { kind: 'definition' }>, state: State): State {
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

/** 定義中のクラスに、メンバー登録または公開の状態遷移を適用する。 */
function definitionDeclaration(directive: ClassDirective, capture: Extract<Capture, { kind: 'definition' }>, state: State): State {
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

/** 現在の構文スコープの収集状態に応じて宣言を処理する。 */
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

/** 通常の関数スコープごとに独立して、構文上のコマンドからクラス宣言を解釈する。 */
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
