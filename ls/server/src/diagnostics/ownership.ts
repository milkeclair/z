import { functionCommand } from '../connection/ast/cursor';
import { literalWord } from '../refreshFunctions/word';
import { classMethodAt, type ZshFileHydration } from '../zshHydrator';
import type { ClassInstance } from '../zshHydrator/classes';
import {
  locate,
  type FunctionDefinitionNode,
  type ListItemNode,
  type ListNode,
  type SimpleCommandNode,
} from '../zshParser/ast';

export type ClassReferenceIssue = {
  readonly code: 'class-reference-moved' | 'class-borrow-readonly';
  readonly message: string;
};

type OwnerBinding = {
  readonly instance: ClassInstance;
  readonly state: 'owner' | 'moved';
};

type Move = {
  readonly from: string;
  readonly to: string;
  readonly instance: ClassInstance;
  readonly offset: number;
  readonly list: ListNode;
  readonly scope: Scope;
};

type Borrow = {
  readonly instance: ClassInstance;
  readonly owner: string;
};

type Scope = FunctionDefinitionNode | SimpleCommandNode | null;
type Site = {
  readonly lists: readonly ListNode[];
  readonly scope: Scope;
};

export type Ownership = {
  readonly moves: readonly Move[];
  readonly callbacks: ReadonlyMap<FunctionDefinitionNode, Borrow | null>;
};

function siteAt(file: ZshFileHydration, offset: number): Site | null {
  const location = locate(file.query, offset);
  if (location?.kind !== 'syntax') return null;

  const scope = location.path.findLast((node) => node.kind === 'functionDefinition') ?? null;
  const method = classMethodAt(file.classes, scope, offset);
  return {
    lists: location.path.filter((node) => node.kind === 'list'),
    scope: method?.declaration ?? scope,
  };
}

function commandName(command: SimpleCommandNode): string | null {
  return command.commandName && functionCommand(command)
    ? literalWord(command.commandName.word)
    : null;
}

function standalone(item: ListItemNode): SimpleCommandNode | null {
  const { sublist, terminator } = item;
  if (
    sublist.kind !== 'sublist' ||
    sublist.rest.length ||
    sublist.first.rest.length ||
    sublist.first.modifier ||
    (terminator && terminator.type !== 'newline' && terminator.type !== 'semicolon')
  )
    return null;

  const command = sublist.first.first;
  return command.kind === 'simpleCommand' ? command : null;
}

function moveCommand(item: ListItemNode): SimpleCommandNode | null {
  const direct = standalone(item);
  if (direct) return direct;

  const { sublist, terminator } = item;
  if (
    sublist.kind !== 'sublist' ||
    sublist.rest.length !== 1 ||
    (terminator && terminator.type !== 'newline' && terminator.type !== 'semicolon')
  )
    return null;

  const { first, rest } = sublist;
  const guard = rest[0];
  if (
    first.modifier ||
    first.rest.length ||
    first.first.kind !== 'simpleCommand' ||
    guard.operator.type !== 'orIf' ||
    guard.pipeline.modifier ||
    guard.pipeline.rest.length ||
    guard.pipeline.first.kind !== 'simpleCommand'
  )
    return null;

  const failure = commandName(guard.pipeline.first);
  return failure === 'return' || failure === 'exit' ? first.first : null;
}

function before(lists: readonly ListNode[], offset: number): readonly SimpleCommandNode[] {
  return lists.flatMap((list) =>
    list.items.flatMap((item) => {
      const command = standalone(item);
      return command && command.range.end.offset <= offset ? [command] : [];
    }),
  );
}

function variable(arg: string | null, name: string): string | null {
  if (!arg?.startsWith(name + '=')) return null;
  const value = arg.slice(name.length + 1);
  return /^[A-Za-z_][A-Za-z_0-9]*$/.test(value) ? value : null;
}

function syntacticScope(instance: ClassInstance): Scope {
  return instance.scope.kind === 'file' ? null : instance.scope.declaration;
}

function visibleInstances(
  file: ZshFileHydration,
  site: Site,
  offset: number,
  binding: string,
): readonly ClassInstance[] {
  return file.classes.instances.filter((instance) => {
    if (
      instance.name !== binding ||
      syntacticScope(instance) !== site.scope ||
      instance.declaration.range.end.offset > offset
    ) {
      return false;
    }
    const list = siteAt(file, instance.declaration.range.start.offset)?.lists.at(-1);
    return list !== undefined && site.lists.includes(list);
  });
}

/** 同じ構文スコープから見える束縛と、先行する移動をソース順で直前の参照に対応付ける。 */
export function ownerAt(
  file: ZshFileHydration,
  binding: string,
  offset: number,
  moves: readonly Move[],
): OwnerBinding | null {
  if (
    !file.classes.instances.some((instance) => instance.name === binding) &&
    !moves.some((move) => move.to === binding || move.from === binding)
  )
    return null;
  const site = siteAt(file, offset);
  if (!site) return null;

  const move = moves.findLast(
    (event) =>
      event.offset <= offset &&
      (event.from === binding || event.to === binding) &&
      event.scope === site.scope &&
      site.lists.includes(event.list),
  );
  if (move) return { instance: move.instance, state: move.from === binding ? 'moved' : 'owner' };

  const candidates = visibleInstances(file, site, offset, binding);
  return candidates.length === 1 ? { instance: candidates[0], state: 'owner' } : null;
}

function declares(command: SimpleCommandNode, name: string): boolean {
  if (command.semantic.role !== 'declaration') return false;
  const declaration = command.semantic.declaration;
  return (
    declaration.names.some((node) => node.value === name) ||
    declaration.assignments.some((assignment) => assignment.name.value === name)
  );
}

function writableDeclaration(command: SimpleCommandNode, name: string): boolean {
  if (command.semantic.role !== 'declaration') return false;
  const declaration = command.semantic.declaration;
  return (
    (declaration.kind === 'local' || declaration.kind === 'typeset') &&
    !declaration.options.length &&
    (declaration.names.some((node) => node.value === name) ||
      declaration.assignments.some(
        (assign) =>
          assign.name.value === name &&
          assign.operator === '=' &&
          !assign.subscript &&
          assign.value?.value.kind === 'word' &&
          literalWord(assign.value.value) === '',
      ))
  );
}

/** 移動の命令と、クラスを特定できる同一ファイルの借用コールバックを収集する。 */
export function classOwnership(
  file: ZshFileHydration,
  commands: readonly SimpleCommandNode[],
): Ownership {
  const callbacks = new Map<FunctionDefinitionNode, Borrow | null>();
  if (!file.classes.instances.length) return { moves: [], callbacks };

  const named = commands.map((command) => ({ command, name: commandName(command) }));
  const moves: Move[] = [];
  for (const { command, name } of named) {
    if (name !== 'z.cls.owner.move' || command.arguments.length !== 2) continue;
    const args = command.arguments.map((word) => literalWord(word));
    const from = args.map((arg) => variable(arg, 'from')).find((value) => value !== null);
    const to = args.map((arg) => variable(arg, 'to')).find((value) => value !== null);
    if (!from || !to || from === to) continue;

    const offset = command.range.start.offset;
    const site = siteAt(file, offset);
    const list = site?.lists.at(-1);
    if (!site || !list) continue;

    const item = list.items.find((entry) => moveCommand(entry) === command);
    const destination = before([list], offset).findLast((entry) => declares(entry, to));
    if (!item || !destination || !writableDeclaration(destination, to)) continue;

    const binding = ownerAt(file, from, offset, moves);
    if (binding?.state !== 'owner' || ownerAt(file, to, offset, moves)) continue;
    moves.push({
      from,
      to,
      offset: item.range.end.offset,
      scope: site.scope,
      list,
      instance: binding.instance,
    });
  }

  const normalCalls = new Set(named.map(({ name }) => name));
  for (const { command, name } of named) {
    if (name !== 'z.cls.borrow' || command.arguments.length !== 2) continue;
    const args = command.arguments.map((word) => literalWord(word));
    const namedIndex = args.findIndex((arg) => arg?.startsWith('from='));
    if (namedIndex === -1) continue;
    const callback = args[1 - namedIndex];
    if (!callback || normalCalls.has(callback)) continue;
    const definitions = file.functions.filter((entry) => entry.name === callback);
    if (definitions.length !== 1) continue;
    const { definition } = definitions[0];
    const start = definition.body.range.start.offset;
    const end = definition.body.range.end.offset;
    if (
      named.some(
        ({ command: candidate, name: called }) =>
          (called === 'shift' || called === 'set') &&
          candidate.range.start.offset >= start &&
          candidate.range.end.offset <= end,
      )
    )
      continue;

    const owner = variable(args[namedIndex], 'from');
    const binding = owner && ownerAt(file, owner, command.range.start.offset, moves);
    const known = owner && binding && binding.state === 'owner' && !callbacks.has(definition);
    callbacks.set(definition, known ? { instance: binding.instance, owner } : null);
  }

  return { moves, callbacks };
}

function borrowedArgument(command: SimpleCommandNode, name: string): boolean {
  if (command.semantic.role !== 'declaration') return false;
  const declaration = command.semantic.declaration;
  return (
    declaration.kind === 'local' &&
    declaration.options.some((option) => option.name.includes('r')) &&
    !declaration.options.some((option) => option.name.includes('g')) &&
    declaration.assignments.some((assign) => {
      const value = assign.value?.value.raw;
      return (
        assign.name.value === name &&
        (value === '$1' || value === '"$1"' || value === '${1}' || value === '"${1}"')
      );
    })
  );
}

/** 借用の第1引数、またはその読み取り専用のローカル名だけを関連付ける。 */
export function borrowAt(
  file: ZshFileHydration,
  binding: string,
  offset: number,
  ownership: Ownership,
): ClassInstance | null {
  if (!ownership.callbacks.size) return null;
  const site = siteAt(file, offset);
  const scope = site?.scope;
  if (!site || scope?.kind !== 'functionDefinition') return null;

  const borrow = ownership.callbacks.get(scope);
  if (!borrow) return null;

  const previous = before(site.lists, offset).filter(
    (command) => command.range.start.offset >= scope.range.start.offset,
  );
  if (binding === '1' || previous.some((command) => borrowedArgument(command, binding))) {
    return borrow.instance;
  }

  const shadowed = previous.some((command) => declares(command, binding));
  return binding === borrow.owner && !shadowed ? borrow.instance : null;
}

/** 所有権を必要とする操作を、静的に特定できる変数名から検証する。 */
export function ownershipOperationIssue(
  file: ZshFileHydration,
  command: SimpleCommandNode,
  ownership: Ownership,
): ClassReferenceIssue | null {
  if (!ownership.moves.length && !ownership.callbacks.size) return null;
  const name = commandName(command);
  if (name !== 'z.cls.owner.move' && name !== 'z.cls.delete') return null;

  const args = command.arguments.map((word) => literalWord(word));
  const binding =
    name === 'z.cls.owner.move'
      ? args.map((arg) => variable(arg, 'from')).find((arg) => arg !== null)
      : args[0];
  if (!binding || !/^[A-Za-z_][A-Za-z_0-9]*$/.test(binding)) return null;

  const offset = command.range.start.offset;
  if (borrowAt(file, binding, offset, ownership)) {
    return {
      code: 'class-borrow-readonly',
      message: name + ' cannot move or delete the borrowed instance ' + binding + '.',
    };
  }
  if (ownerAt(file, binding, offset, ownership.moves)?.state === 'moved') {
    return {
      code: 'class-reference-moved',
      message: name + ' uses the reference ' + binding + ' whose ownership was moved.',
    };
  }

  return null;
}
