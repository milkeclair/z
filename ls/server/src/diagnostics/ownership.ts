import { namedKey } from '../connection/ast/word';
import { literalWord } from '../refreshFunctions/word';
import { classMethodAt, documentationOf, type ZshFileHydration } from '../zshHydrator';
import type { ClassInstance } from '../zshHydrator/classes';
import { classArguments, commandName, parameterAt, variableArgument } from './classContracts';
import {
  locate,
  type FunctionDefinitionNode,
  type ListItemNode,
  type ListNode,
  type SimpleCommandNode,
} from '../zshParser/ast';

export type ClassReferenceIssue = {
  readonly code:
    | 'class-reference-moved'
    | 'class-readonly-write'
    | 'class-argument-type'
    | 'class-owner-required'
    | 'class-reference-uninitialized';
  readonly message: string;
};

type OwnerBinding = {
  readonly instance: ClassInstance | null;
  readonly className: string;
  readonly state: 'owner' | 'moved' | 'maybe-moved' | 'maybe-uninitialized';
};

type Move = {
  readonly from: string;
  readonly to: string | null;
  readonly instance: ClassInstance | null;
  readonly className: string;
  readonly offset: number;
  readonly list: ListNode;
  readonly scope: Scope;
  readonly conditional: { readonly list: ListNode; readonly offset: number } | null;
};

type Scope = FunctionDefinitionNode | SimpleCommandNode | null;
type Site = {
  readonly lists: readonly ListNode[];
  readonly scope: Scope;
};

export type Ownership = {
  readonly moves: readonly Move[];
  readonly typedFunctions: boolean;
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

  for (let index = moves.length - 1; index >= 0; index--) {
    const event = moves[index];
    if (event.offset > offset || event.scope !== site.scope) continue;
    if (event.from !== binding && event.to !== binding) continue;
    if (site.lists.includes(event.list)) {
      return {
        instance: event.instance,
        className: event.className,
        state: event.from === binding ? 'moved' : 'owner',
      };
    }
    if (
      event.conditional &&
      event.conditional.offset <= offset &&
      site.lists.includes(event.conditional.list)
    ) {
      return {
        instance: event.instance,
        className: event.className,
        state: event.from === binding ? 'maybe-moved' : 'maybe-uninitialized',
      };
    }
  }

  const candidates = visibleInstances(file, site, offset, binding);
  return candidates.length === 1
    ? { instance: candidates[0], className: candidates[0].className, state: 'owner' }
    : null;
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

function afterConditional(file: ZshFileHydration, offset: number): Move['conditional'] {
  const location = locate(file.query, offset);
  if (location?.kind !== 'syntax') return null;
  const path = location.path;
  const branch = path.findLastIndex((node) => node.kind === 'ifCommand');
  if (
    branch < 0 ||
    path
      .slice(branch + 1)
      .some(
        (node) =>
          node.kind === 'subshellCommand' ||
          node.kind === 'functionDefinition' ||
          node.kind === 'commandSubstitution' ||
          node.kind === 'processSubstitution',
      )
  )
    return null;
  const arm = path.slice(branch + 1).find((node) => node.kind === 'ifBranch');
  const condition = arm?.condition.items.length === 1 ? standalone(arm.condition.items[0]) : null;
  if (condition && commandName(condition) === 'false' && !condition.arguments.length) return null;

  const branchLists = path.slice(branch + 1).filter((node) => node.kind === 'list');
  if (
    branchLists.some((list) =>
      list.items.some((item) => {
        if (item.range.start.offset <= offset) return false;
        const command = standalone(item);
        const name = command && commandName(command);
        return name === 'return' || name === 'exit';
      }),
    )
  )
    return null;

  const parent = path.slice(0, branch).findLast((node) => node.kind === 'list');
  const command = path[branch];
  return parent ? { list: parent, offset: command.range.end.offset } : null;
}

/** 明示された移動と、関数の所有権引数で消費される変数を記録する。 */
export function classOwnership(
  file: ZshFileHydration,
  commands: readonly SimpleCommandNode[],
  resolve: (name: string, offset: number) => FunctionDefinitionNode | null,
): Ownership {
  const moves: Move[] = [];
  const typedFunctions = file.functions.some(({ definition }) =>
    documentationOf(definition)?.parameters.some((parameter) => parameter.classReference),
  );
  if (!file.classes.instances.length && !typedFunctions) return { moves, typedFunctions };

  for (const command of commands) {
    const name = commandName(command);
    if (!name) continue;
    const offset = command.range.start.offset;

    if (name === 'z.cls.owner.move') {
      const args = command.arguments.map((word) => literalWord(word));
      const direct = args.map((arg) => variable(arg, 'from')).find((value) => value !== null);
      const source = command.arguments.find((argument) => namedKey(argument) === 'from');
      const from = direct ?? (source && variableArgument(source, 'from'));
      const to = args.map((arg) => variable(arg, 'to')).find((value) => value !== null);
      if (!from || !to || from === to || args.length !== 2) continue;

      const site = siteAt(file, offset);
      const list = site?.lists.at(-1);
      if (!site || !list) continue;
      const item = list.items.find((entry) => moveCommand(entry) === command);
      const destination = before(site.lists, offset).findLast((entry) => declares(entry, to));
      if (!item || !destination || !writableDeclaration(destination, to)) continue;

      const binding = ownerAt(file, from, offset, moves);
      const formal =
        !direct && typedFunctions ? parameterAt(file, from, offset)?.classReference : undefined;
      const className =
        binding?.state === 'owner'
          ? binding.className
          : formal?.access === 'owner'
            ? formal.className
            : null;
      if (!className || ownerAt(file, to, offset, moves)) continue;
      moves.push({
        from,
        to,
        offset: item.range.end.offset,
        scope: site.scope,
        list,
        instance: binding?.instance ?? null,
        className,
        conditional: afterConditional(file, offset),
      });
      continue;
    }

    const target = resolve(name, offset);
    if (!target) continue;
    const consumed = classArguments(command, target).filter(
      ({ type, ownerName }) => type.access === 'owner' && ownerName,
    );
    if (!consumed.length) continue;

    const site = siteAt(file, offset);
    const list = site?.lists.at(-1);
    if (!site || !list) continue;
    const item = list.items.find((entry) => moveCommand(entry) === command);
    if (!item) continue;

    for (const { type, ownerName: from } of consumed) {
      if (!from) continue;
      const binding = ownerAt(file, from, offset, moves);
      if (binding?.state !== 'owner' || binding.className !== type.className) continue;
      moves.push({
        from,
        to: null,
        offset: item.range.end.offset,
        scope: site.scope,
        list,
        instance: binding.instance,
        className: binding.className,
        conditional: afterConditional(file, offset),
      });
    }
  }

  return { moves, typedFunctions };
}

/** 所有権を必要とする操作を、静的に特定できる変数名から検証する。 */
export function ownershipOperationIssue(
  file: ZshFileHydration,
  command: SimpleCommandNode,
  ownership: Ownership,
): ClassReferenceIssue | null {
  const name = commandName(command);
  if (name !== 'z.cls.owner.move' && name !== 'z.cls.delete') return null;
  const key = name === 'z.cls.owner.move' ? 'from' : undefined;
  const argument = key
    ? command.arguments.find((word) => namedKey(word) === key)
    : command.arguments[0];
  if (!argument) return null;

  const literal = literalWord(argument);
  const binding =
    variable(literal, key ?? '') ?? (key ? null : literal) ?? variableArgument(argument, key);
  if (!binding) return null;

  const offset = command.range.start.offset;
  const reference = ownership.typedFunctions
    ? parameterAt(file, binding, offset)?.classReference
    : undefined;
  if (reference && reference.access !== 'owner') {
    return {
      code: 'class-owner-required',
      message: name + ' requires ownership of ' + binding + '.',
    };
  }
  const state = ownerAt(file, binding, offset, ownership.moves)?.state;
  if (state === 'moved' || state === 'maybe-moved') {
    return {
      code: 'class-reference-moved',
      message:
        name +
        ' uses the reference ' +
        binding +
        (state === 'moved' ? ' whose ownership was moved.' : ' whose ownership may have moved.'),
    };
  }
  return null;
}
