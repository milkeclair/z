import { functionCommand } from '../connection/ast/cursor';
import { namedKey } from '../connection/ast/word';
import { literalWord } from '../refreshFunctions/word';
import { classMethodAt, documentationOf, type ZshFileHydration } from '../zshHydrator';
import type { ParameterDoc } from '../zshHydrator/documentation/types';
import {
  findAll,
  locate,
  type CommandNode,
  type FunctionDefinitionNode,
  type ListNode,
  type SimpleCommandNode,
  type WordNode,
} from '../zshParser/ast';

const variablePattern = /^[A-Za-z_][A-Za-z_0-9]*$/;

export function variableName(value: string | null): string | null {
  return value && variablePattern.test(value) ? value : null;
}

/** 静的に追跡できる単一の変数展開を、名前付き引数も含めて取得する。 */
export function variableArgument(word: WordNode, key?: string): string | null {
  const raw = word.raw;
  const text = raw.startsWith('"') && raw.endsWith('"') ? raw.slice(1, -1) : raw;
  const prefix = key ? key + '=' : '';
  if (!text.startsWith(prefix)) return null;
  const value = text.slice(prefix.length);
  const unquoted = value.startsWith('"') && value.endsWith('"') ? value.slice(1, -1) : value;
  return (
    /^\$(?:\{([A-Za-z_][A-Za-z_0-9]*|[1-9][0-9]*)\}|([A-Za-z_][A-Za-z_0-9]*|[1-9][0-9]*))$/
      .exec(unquoted)
      ?.slice(1)
      .find(Boolean) ?? null
  );
}

export function commandName(command: SimpleCommandNode): string | null {
  return command.commandName && functionCommand(command)
    ? literalWord(command.commandName.word)
    : null;
}

export function classArguments(command: SimpleCommandNode, definition: FunctionDefinitionNode) {
  const parameters = documentationOf(definition)?.parameters ?? [];
  if (!parameters.some((parameter) => parameter.classReference)) return [];

  const named = new Set(
    parameters.flatMap((p) => (p.kind === 'namedParameterDoc' ? [p.name] : [])),
  );
  const positional = command.arguments.filter((word) => !named.has(namedKey(word) ?? ''));
  return parameters.flatMap((parameter) => {
    const type = parameter.classReference;
    if (!type || parameter.kind === 'restParameterDoc') return [];
    const key = parameter.kind === 'namedParameterDoc' ? parameter.name : undefined;
    const word =
      parameter.kind === 'namedParameterDoc'
        ? command.arguments.find((argument) => namedKey(argument) === key)
        : positional[parameter.position - 1];
    if (!word) return [];
    const literal = literalWord(word);
    const value = literal?.slice(key ? key.length + 1 : 0) ?? null;
    const ownerName = type.access === 'owner' ? variableName(value) : null;
    return [
      {
        type,
        word,
        literal: value,
        ownerName,
        binding: ownerName ?? variableArgument(word, key),
      },
    ];
  });
}

function declarationSource(
  command: SimpleCommandNode,
  name: string,
): { readonly source: string | null } | null {
  if (command.prefixAssignments.some((assignment) => assignment.name.value === name)) {
    return { source: null };
  }
  if (command.semantic.role !== 'declaration') return null;
  const declaration = command.semantic.declaration;
  const assignment = declaration.assignments.find((entry) => entry.name.value === name);
  if (assignment) {
    return {
      source:
        declaration.kind === 'local' &&
        !declaration.options.some((option) => option.name.includes('g')) &&
        assignment.operator === '=' &&
        !assignment.subscript &&
        assignment.value
          ? variableArgument(assignment.value.value)
          : null,
    };
  }
  return declaration.names.some((entry) => entry.value === name) ? { source: null } : null;
}

function argumentAlias(
  lists: readonly ListNode[],
  definition: FunctionDefinitionNode,
  name: string,
  offset: number,
): { readonly source: string; readonly kind: 'named' | 'positional' } | null {
  for (const list of lists.toReversed()) {
    for (const item of list.items.toReversed()) {
      if (
        item.range.end.offset > offset ||
        item.range.start.offset < definition.body.range.start.offset
      )
        continue;
      const { sublist } = item;
      if (sublist.kind !== 'sublist' || sublist.first.rest.length || sublist.first.modifier)
        continue;
      const head = sublist.first.first;
      const tail = sublist.rest[0];
      if (!tail && head.kind === 'simpleCommand') {
        const value = declarationSource(head, name);
        if (value) return value.source ? { source: value.source, kind: 'positional' } : null;
        continue;
      }
      if (
        head.kind !== 'simpleCommand' ||
        sublist.rest.length !== 1 ||
        tail.operator.type !== 'andIf' ||
        tail.pipeline.rest.length ||
        tail.pipeline.modifier ||
        tail.pipeline.first.kind !== 'simpleCommand'
      )
        continue;
      const value = declarationSource(tail.pipeline.first, name);
      if (!value) continue;
      const key = head.arguments[0] && literalWord(head.arguments[0]);
      return commandName(head) === 'z.arg.named' &&
        key &&
        value.source === 'REPLY' &&
        head.arguments[1]?.raw === '"$@"'
        ? { source: key, kind: 'named' }
        : null;
    }
  }
  return null;
}

/** 関数自身のコメントから、引数または引数を受け取ったローカル変数の契約を取得する。 */
export function parameterAt(
  file: ZshFileHydration,
  binding: string,
  offset: number,
): ParameterDoc | null {
  const location = locate(file.query, offset);
  if (location?.kind !== 'syntax') return null;
  const definition = location.path.findLast((node) => node.kind === 'functionDefinition');
  if (!definition || classMethodAt(file.classes, definition, offset)) return null;
  const parameters = documentationOf(definition)?.parameters;
  if (!parameters?.some((parameter) => parameter.classReference)) return null;
  const alias = /^[1-9][0-9]*$/.test(binding)
    ? { source: binding, kind: 'positional' }
    : argumentAlias(
        location.path.filter((node) => node.kind === 'list'),
        definition,
        binding,
        offset,
      );
  if (!alias) return null;

  return (
    parameters.find(
      (parameter) =>
        parameter.classReference &&
        (alias.kind === 'named'
          ? parameter.kind === 'namedParameterDoc' && parameter.name === alias.source
          : parameter.kind === 'positionalParameterDoc' &&
            String(parameter.position) === alias.source),
    ) ?? null
  );
}

type Pending = 'continues' | 'moved' | 'returns';

/** まだ移動していない経路だけを独立に調べる。 */
function beforeMove(
  file: ZshFileHydration,
  list: ListNode,
  parameter: ParameterDoc,
  depth: number,
): Pending {
  if (depth >= 64) return 'returns';

  for (const item of list.items) {
    if (item.sublist.kind !== 'sublist') continue;
    const pipeline = item.sublist.first;
    if (
      pipeline.rest.length ||
      pipeline.modifier ||
      item.terminator?.type.startsWith('background')
    ) {
      continue;
    }

    const result = commandBeforeMove(file, pipeline.first, parameter, depth);
    if (result !== 'continues') return result;
    for (const tail of item.sublist.rest) {
      if (
        !tail.pipeline.rest.length &&
        !tail.pipeline.modifier &&
        commandBeforeMove(file, tail.pipeline.first, parameter, depth) === 'returns'
      ) {
        return 'returns';
      }
    }
  }
  return 'continues';
}

function commandBeforeMove(
  file: ZshFileHydration,
  command: CommandNode,
  parameter: ParameterDoc,
  depth: number,
): Pending {
  switch (command.kind) {
    case 'simpleCommand': {
      const name = commandName(command);
      if (name === 'return') return 'returns';
      if (name === 'exit') return 'moved';
      if (name !== 'z.cls.owner.move') return 'continues';

      if (
        command.arguments.length !== 2 ||
        !command.arguments.some((word) => namedKey(word) === 'to')
      )
        return 'continues';

      const argument = command.arguments.find((word) => namedKey(word) === 'from');
      const binding = argument && variableArgument(argument, 'from');
      return binding && parameterAt(file, binding, command.range.start.offset) === parameter
        ? 'moved'
        : 'continues';
    }
    case 'ifCommand': {
      let continues = false;
      for (const branch of command.branches) {
        const condition = beforeMove(file, branch.condition, parameter, depth + 1);
        if (condition === 'returns') return 'returns';
        if (condition === 'moved') return continues ? 'continues' : 'moved';

        const body = beforeMove(file, branch.body, parameter, depth + 1);
        if (body === 'returns') return 'returns';
        continues ||= body === 'continues';
      }
      const alternative = command.elseBody
        ? beforeMove(file, command.elseBody, parameter, depth + 1)
        : 'continues';
      return alternative === 'returns'
        ? 'returns'
        : continues || alternative === 'continues'
          ? 'continues'
          : 'moved';
    }
    case 'groupCommand':
      if (!command.always) return beforeMove(file, command.body, parameter, depth + 1);
      break;
    case 'functionDefinition':
    case 'subshellCommand':
      return 'continues';
  }

  return findAll(command, 'simpleCommand').some((part) => commandName(part) === 'return')
    ? 'returns'
    : 'continues';
}

export function invalidOwnerParameters(file: ZshFileHydration, definition: FunctionDefinitionNode) {
  return (documentationOf(definition)?.parameters ?? []).filter(
    (parameter) =>
      parameter.classReference?.access === 'owner' &&
      commandBeforeMove(file, definition.body, parameter, 0) !== 'moved',
  );
}
