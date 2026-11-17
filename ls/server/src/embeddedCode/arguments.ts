import { appendItems, collectArray } from '../util/collections';
import { namedKey } from '../connection/ast/word';
import type { ResolutionContext } from '../diagnostics/calls';
import { uncertainWord } from '../diagnostics/calls';
import { documentationOf } from '../zshHydrator';
import type { ParameterDoc } from '../zshHydrator/documentation';
import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import type { DecodedLiteral } from './literal';
import { decodeLiteral, literalValue } from './literal';

export type CodeArgument =
  | {
      readonly kind: 'code';
      readonly word: WordNode;
      readonly source: DecodedLiteral;
      readonly prefix: string;
    }
  | {
      readonly kind: 'limit';
      readonly word: WordNode;
    };

type ParameterIndex = {
  readonly named: ReadonlyMap<string, ParameterDoc>;
  readonly positional: ReadonlyMap<number, ParameterDoc>;
  readonly rest: ParameterDoc | undefined;
  readonly lastPosition: number;
};

type ArgumentProgress = {
  readonly position: number;
  readonly uncertain: boolean;
  readonly result: ReadonlyArray<CodeArgument>;
  readonly remaining: number;
};

type SelectedParameter = {
  readonly parameter: ParameterDoc | undefined;
  readonly prefix: number;
  readonly position: number;
  readonly uncertain: boolean;
};

function indexParameters(parameters: readonly ParameterDoc[]): ParameterIndex {
  const named = new Map(
    parameters.flatMap((parameter) =>
      parameter.kind === 'namedParameterDoc' ? [[parameter.name, parameter]] : [],
    ),
  );
  const positional = new Map(
    parameters.flatMap((parameter) =>
      parameter.kind === 'positionalParameterDoc' ? [[parameter.position, parameter]] : [],
    ),
  );

  return {
    named,
    positional,
    rest: parameters.find((parameter) => parameter.kind === 'restParameterDoc'),
    lastPosition: [...positional.keys()].reduce(
      (maximum, position) => Math.max(maximum, position),
      0,
    ),
  };
}

function selectParameter(
  word: WordNode,
  previous: ArgumentProgress,
  parameters: ParameterIndex,
  context: ResolutionContext,
): SelectedParameter | null {
  const key = namedKey(word);

  if (key && parameters.named.has(key)) {
    return {
      parameter: parameters.named.get(key),
      prefix: key.length + 1,
      position: previous.position,
      uncertain: previous.uncertain,
    };
  }

  if (previous.uncertain) {
    return null;
  }

  const position = previous.position + 1;

  return {
    parameter:
      parameters.positional.get(position) ??
      (position > parameters.lastPosition ? parameters.rest : undefined),
    prefix: 0,
    position,
    uncertain: uncertainWord(word, context),
  };
}

function inspectCodeArgument(
  word: WordNode,
  previous: ArgumentProgress,
  selected: SelectedParameter,
  context: ResolutionContext,
  allowUnterminated: boolean,
): ArgumentProgress {
  const current = { ...previous, position: selected.position, uncertain: selected.uncertain };
  const { parameter, prefix } = selected;

  if (parameter?.valueType !== 'code' || uncertainWord(word, context)) {
    return current;
  }

  if (word.raw.length > current.remaining) {
    return { ...current, result: appendItems(current.result, { kind: 'limit', word }) };
  }

  const bounded = { ...current, remaining: current.remaining - word.raw.length };
  const decoded = decodeLiteral(word, allowUnterminated);

  if (!decoded) {
    return bounded;
  }

  const source = literalValue(decoded, prefix);

  if (parameter.literalValues?.includes(source.text)) {
    return bounded;
  }

  return {
    ...bounded,
    result: appendItems(bounded.result, {
      kind: 'code',
      word,
      source,
      prefix: decoded.text.slice(0, prefix),
    }),
  };
}

/** 文書でコード型を指定した引数を対応付け、引数の個数が不確かな場合は保留し、復号量を文字数の上限に計上する。 */
export function codeArguments(
  command: SimpleCommandNode,
  target: FunctionDefinitionNode,
  context: ResolutionContext,
  maxText = 1024 * 1024,
  allowUnterminated = false,
): {
  readonly arguments: readonly CodeArgument[];
  readonly inspected: number;
} {
  const parameters = documentationOf(target)?.parameters ?? [];

  if (!parameters.some((parameter) => parameter.valueType === 'code')) {
    return { arguments: [], inspected: 0 };
  }

  const indexed = indexParameters(parameters);
  const initial: ArgumentProgress = {
    position: 0,
    uncertain: false,
    result: collectArray(),
    remaining: maxText,
  };
  const parsed = command.arguments.reduce((previous, word) => {
    const selected = selectParameter(word, previous, indexed, context);

    return selected
      ? inspectCodeArgument(word, previous, selected, context, allowUnterminated)
      : previous;
  }, initial);

  return { arguments: parsed.result, inspected: maxText - parsed.remaining };
}
