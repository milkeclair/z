import { methodArguments, methodReceivers } from './method';
import type { ClassMethodAccess } from './types';
import { castDraft } from 'immer';
import { addValue, appendItems, makeMap, makeSet, produce, setEntry } from '../../util/collections';
import { again, done, loop } from '../../util/loop';
import { pushStack, type Stack } from '../../util/stack';
import type {
  AstNode,
  FileNode,
  FunctionDefinitionNode,
  ListItemNode,
  SimpleCommandNode,
} from '../../zshParser/ast';
import { foldAst } from '../../zshParser/ast';
import { standalonePipeline } from '../../zshParser/ast/listItem';
import type { FoldStep } from '../../zshParser/ast/traversal/walk';
import { literalWord } from '../../zshParser/ast/word/literal';
import type { SourceRange } from '../../zshParser/lexer';
import { attributeArguments } from './attribute';
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
  readonly failed: boolean;
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
      readonly access: ClassMethodAccess;
      readonly depth: number;
    }
  | {
      readonly kind: 'rejected';
      readonly outer: Capture | undefined;
      readonly methodDepth: number | null;
    };
type State = {
  readonly receiverAccess: ReturnType<typeof methodReceivers>;
  readonly captures: ReadonlyMap<FunctionDefinitionNode | undefined, Capture>;
  readonly information: ReadonlyMap<number, ClassInformation | null>;
  readonly published: ReadonlyMap<FunctionDefinitionNode | undefined, ReadonlySet<string>>;
};

type ClassDirective = {
  readonly command: SimpleCommandNode;
  readonly name: string;
  readonly args: readonly (string | null)[];
  readonly depth: number;
  readonly scope: FunctionDefinitionNode | undefined;
  readonly standalone: boolean;
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
      access: capture.access,
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
  capture: Extract<Capture, { kind: 'definition' | 'method' }>,
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

  const published =
    status === 'published'
      ? setEntry(
          state.published,
          scope,
          addValue(state.published.get(scope) ?? makeSet<string>(), definition.name),
        )
      : state.published;

  return { ...withCapture(state, scope, null), information, published };
}

/** 引数を実行せず、通常の構文から静的な宣言を1つ読む。 */
function readClassDirective(
  command: SimpleCommandNode,
  depth: number,
  scope: FunctionDefinitionNode | undefined,
  standalone: boolean,
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
    'z.cls.method',
    'z.cls.method.defined',
    'z.cls.drew',
    'z.cls.abort',
    'z.cls.new',
  ];
  if (!names.includes(name)) return null;

  return {
    command,
    name,
    args: command.arguments.map((word) => literalWord(word)),
    depth,
    scope,
    standalone,
  };
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

function isMethodEnd(directive: ClassDirective, depth: number): boolean {
  return (
    directive.depth === depth &&
    directive.standalone &&
    directive.name === 'z.cls.method.defined' &&
    directive.args.length === 0
  );
}

/** メソッド開始時と同じ構文の深さにある終了マーカーだけを処理する。 */
function applyMethodDirective(
  directive: ClassDirective,
  capture: Extract<Capture, { kind: 'method' }>,
  state: State,
): State {
  return isMethodEnd(directive, capture.depth)
    ? withMember(
        state,
        directive.scope,
        capture.definition,
        blockMethodFromCapture(capture, directive.command.range, true),
      )
    : state;
}

/** クラス内で最初に現れた有効な属性宣言を保持する。 */
function declareAttribute(directive: ClassDirective, definition: Definition, state: State): State {
  const attribute = attributeArguments(directive.command);
  const name = attribute && literalWord(attribute.nameNode);
  const duplicate = definition.members.some(
    (member) => member.information.kind === 'classAttribute' && member.information.name === name,
  );
  if (!attribute || !identifier(name) || duplicate) {
    return withCapture(state, directive.scope, {
      kind: 'definition',
      definition: { ...definition, failed: true },
    });
  }

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
  const method = methodArguments(directive.command);
  if (!identifier(name) || !method) return state;

  const definition = capture.definition;
  const access = state.receiverAccess(directive.command, definition.name);
  const duplicate = definition.members.some(
    (member) => member.information.kind === 'classMethod' && member.information.name === name,
  );
  if (duplicate) {
    return !method.body
      ? finishDefinition(state, directive.scope, capture, directive.command.range, 'aborted')
      : state;
  }

  if (!method.body) {
    return withCapture(state, directive.scope, {
      kind: 'method',
      definition,
      node: directive.command,
      name,
      depth: directive.depth,
      access,
    });
  }

  return withMember(state, directive.scope, definition, {
    node: directive.command,
    information: {
      kind: 'classMethod',
      name,
      access,
      classOffset: definition.node.range.start.offset,
      body: { kind: 'inline', range: method.body.range },
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
    case 'z.cls.method':
      return declareMethod(directive, capture, state);
    case 'z.cls.drew':
      return directive.args.length === 0
        ? finishDefinition(
            state,
            directive.scope,
            capture,
            directive.command.range,
            capture.definition.failed ? 'aborted' : 'published',
          )
        : state;
    case 'z.cls.abort':
      return finishDefinition(state, directive.scope, capture, directive.command.range, 'aborted');
    default:
      return state;
  }
}

/** 拒否した定義のメンバーや終端を、外側で収集中のクラスへ混ぜない。 */
function applyRejectedDirective(
  directive: ClassDirective,
  capture: Extract<Capture, { kind: 'rejected' }>,
  state: State,
): State {
  if (!directive.standalone) return state;

  if (capture.methodDepth !== null) {
    return isMethodEnd(directive, capture.methodDepth)
      ? withCapture(state, directive.scope, { ...capture, methodDepth: null })
      : state;
  }

  if (directive.name === 'z.cls.draw') {
    return withCapture(state, directive.scope, {
      kind: 'rejected',
      outer: capture,
      methodDepth: null,
    });
  }

  if (directive.name === 'z.cls.drew' && directive.args.length === 0) {
    return withCapture(state, directive.scope, capture.outer ?? null);
  }

  const method = directive.name === 'z.cls.method' ? methodArguments(directive.command) : null;
  return method && !method.body
    ? withCapture(state, directive.scope, { ...capture, methodDepth: directive.depth })
    : state;
}

/** 現在の構文スコープの収集状態に応じて宣言を処理する。 */
function collectCommand(
  command: SimpleCommandNode,
  depth: number,
  scope: FunctionDefinitionNode | undefined,
  standalone: boolean,
  state: State,
): State {
  const directive = readClassDirective(command, depth, scope, standalone);
  if (!directive) return state;

  const capture = state.captures.get(scope);
  if (capture?.kind === 'rejected') return applyRejectedDirective(directive, capture, state);
  if (directive.name === 'z.cls.new') return declareInstance(directive, capture, state);
  if (capture?.kind === 'method') return applyMethodDirective(directive, capture, state);

  if (directive.name === 'z.cls.draw') {
    if (
      directive.args.length === 1 &&
      identifier(directive.args[0]) &&
      !capture &&
      !state.published.get(scope)?.has(directive.args[0])
    ) {
      return withCapture(state, scope, {
        kind: 'definition',
        definition: { node: command, name: directive.args[0], members: [], failed: false },
      });
    }

    return withCapture(state, scope, { kind: 'rejected', outer: capture, methodDepth: null });
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
  readonly standaloneCommand: SimpleCommandNode | null;
};

function standaloneCommand(item: ListItemNode): SimpleCommandNode | null {
  const pipeline = standalonePipeline(item);
  const command = pipeline?.first;

  return pipeline &&
    !pipeline.timing &&
    command?.kind === 'simpleCommand' &&
    command.precommandModifiers.length === 0
    ? command
    : null;
}

/** 構文スコープを進め、1ノード分の収集状態と探索制御を返す。 */
function collectNode(
  previous: CollectionProgress,
  node: AstNode,
  depth: number,
): FoldStep<CollectionProgress> {
  const active = loop<Stack<FunctionScope> | null, Stack<FunctionScope> | null>(
    previous.functionScopes,
    (scopes) => (scopes && scopes.value.depth >= depth ? again(scopes.next) : done(scopes)),
  );
  const rejected = previous.collected.captures.get(active?.value.node)?.kind === 'rejected';
  if (
    rejected &&
    (node.kind === 'functionDefinition' ||
      node.kind === 'commandSubstitution' ||
      node.kind === 'processSubstitution' ||
      node.kind === 'subshellCommand')
  ) {
    return {
      state: { ...previous, functionScopes: active },
      control: 'skip',
    };
  }

  const functionScopes =
    node.kind === 'functionDefinition' ? pushStack({ node, depth }, active) : active;
  const standalone =
    node.kind === 'listItem' ? standaloneCommand(node) : previous.standaloneCommand;

  if (node.kind !== 'simpleCommand') {
    return { state: { ...previous, functionScopes, standaloneCommand: standalone } };
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
      collected: collectCommand(
        node,
        depth,
        functionScopes?.value.node,
        standalone === node,
        collected,
      ),
      functionScopes,
      standaloneCommand: standalone,
    },
  };
}

/** 終端のない定義を、それぞれの所有スコープの末尾で確定する。 */
function finishOpenDefinitions(ast: FileNode, collected: State): State {
  return [...collected.captures].reduce((state, [scope, capture]) => {
    const active = loop<
      Capture | undefined,
      Extract<Capture, { kind: 'definition' | 'method' }> | undefined
    >(capture, (current) => (current?.kind === 'rejected' ? again(current.outer) : done(current)));
    if (!active) return state;

    const end = scope?.range.end ?? ast.range.end;
    return finishDefinition(state, scope, active, { start: end, end }, 'incomplete');
  }, collected);
}

/** 通常の関数スコープごとに独立して、構文上のコマンドからクラス宣言を解釈する。 */
export function collectClassInformation(
  ast: FileNode,
  source: string,
): ReadonlyMap<number, ClassInformation | null> {
  const initial: CollectionProgress = {
    collected: {
      captures: makeMap(),
      information: makeMap(),
      published: makeMap(),
      receiverAccess: methodReceivers(ast.comments, source),
    },
    functionScopes: null,
    standaloneCommand: null,
  };
  const progress = foldAst(ast, initial, collectNode);
  return finishOpenDefinitions(ast, progress.collected).information;
}
