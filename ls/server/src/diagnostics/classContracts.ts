import { functionCommand } from '../connection/ast/cursor';
import { namedKey, zArgNamedKey } from '../connection/ast/word';
import { literalWord } from '../refreshFunctions/word';
import { classMethodAt, documentationOf, type ZshFileHydration } from '../zshHydrator';
import {
  documentedArguments,
  type DocumentedArgument,
} from '../zshHydrator/documentation/arguments';
import type { ParameterDoc } from '../zshHydrator/documentation/types';
import {
  findAll,
  locate,
  type CommandNode,
  type FunctionDefinitionNode,
  type ListNode,
  type SimpleCommandNode,
  type WordNode,
  type WordPartNode,
} from '../zshParser/ast';
import { isVariableName } from '../zshParser/parser/word/variableName';

const positionalPattern = /^[1-9][0-9]*$/;

export function variableName(value: string | null): string | null {
  return value && isVariableName(value) ? value : null;
}

/** 実体参照として静的に追跡できる変数名または位置引数番号を取得する。 */
export function classReferenceBinding(part: WordPartNode): string | null {
  if (part.kind === 'variableReference') {
    return part.name.value;
  }

  if (part.kind !== 'parameterExpansion') {
    return null;
  }

  const name =
    part.raw[1] === '{' && part.raw.endsWith('}') ? part.raw.slice(2, -1) : part.raw.slice(1);

  return part.raw.startsWith('$') && (variableName(name) || positionalPattern.test(name))
    ? name
    : null;
}

/** 静的に追跡できる単一の変数展開を、名前付き引数も含めて取得する。 */
export function variableArgument(word: WordNode, key?: string): string | null {
  const part = word.parts.find((entry) => entry.kind !== 'stringLiteral');
  const binding = part && classReferenceBinding(part);

  if (!part || !binding) {
    return null;
  }

  const start = word.range.start.offset;
  const expansion = word.raw.slice(part.range.start.offset - start, part.range.end.offset - start);
  const prefix = key ? key + '=' : '';
  const value = prefix + expansion;
  const quotedExpansion = prefix + '"' + expansion + '"';

  return word.raw === value ||
    word.raw === '"' + value + '"' ||
    word.raw === quotedExpansion ||
    word.raw === '"' + quotedExpansion + '"'
    ? binding
    : null;
}

export function commandName(command: SimpleCommandNode): string | null {
  return command.commandName && functionCommand(command)
    ? literalWord(command.commandName.word)
    : null;
}

export function classArguments(
  command: SimpleCommandNode,
  definition: FunctionDefinitionNode,
  isUncertain: (word: WordNode) => boolean,
) {
  const parameters = documentationOf(definition)?.parameters ?? [];

  if (!parameters.some((parameter) => parameter.classReference)) {
    return [];
  }

  const firstByParameter = new Map<ParameterDoc, DocumentedArgument>();
  for (const argument of documentedArguments(command.arguments, parameters, isUncertain)) {
    const parameter = argument.parameter;

    if (parameter?.classReference && !firstByParameter.has(parameter)) {
      firstByParameter.set(parameter, argument);
    }
  }

  return parameters.flatMap((parameter) => {
    const type = parameter.classReference;
    const argument = firstByParameter.get(parameter);

    if (!type || !argument) {
      return [];
    }

    const { word, key, uncertain } = argument;
    const reference = variableArgument(word, key);

    // 引数数が不明な位置でも、単一の変数参照として読める値は契約を調べられる。
    if (uncertain && !reference) {
      return [];
    }

    const literal = literalWord(word)?.slice(key ? key.length + 1 : 0) ?? null;
    const ownerName = type.access === 'owner' ? variableName(literal) : null;

    return [{ type, word, literal, ownerName, binding: ownerName ?? reference }];
  });
}

function declarationSource(
  command: SimpleCommandNode,
  name: string,
): { readonly source: string | null } | null {
  if (command.prefixAssignments.some((assignment) => assignment.name.value === name)) {
    return { source: null };
  }

  if (command.semantic.role !== 'declaration') {
    return null;
  }

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
      ) {
        continue;
      }

      const { sublist } = item;

      if (sublist.kind !== 'sublist' || sublist.first.rest.length || sublist.first.modifier) {
        continue;
      }

      const head = sublist.first.first;
      const tail = sublist.rest[0];

      if (!tail && head.kind === 'simpleCommand') {
        const value = declarationSource(head, name);

        if (value) {
          return value.source ? { source: value.source, kind: 'positional' } : null;
        }

        continue;
      }

      if (
        head.kind !== 'simpleCommand' ||
        sublist.rest.length !== 1 ||
        tail.operator.type !== 'andIf' ||
        tail.pipeline.rest.length ||
        tail.pipeline.modifier ||
        tail.pipeline.first.kind !== 'simpleCommand'
      ) {
        continue;
      }

      const value = declarationSource(tail.pipeline.first, name);

      if (!value) {
        continue;
      }

      const key = zArgNamedKey(head);

      return key &&
        functionCommand(head) &&
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
  const alias = positionalPattern.test(binding)
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
