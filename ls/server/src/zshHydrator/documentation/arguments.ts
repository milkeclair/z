import type { WordNode } from '../../zshParser/ast';
import { namedKey } from '../../zshParser/ast/word/literal';
import type { ParameterDoc } from './types';

export type DocumentedArgument = {
  readonly word: WordNode;
  readonly parameter: ParameterDoc;
  readonly key?: string;
  readonly uncertain: boolean;
};

/** 個数の不明な展開以降は、静的なキーで対応付けられる引数だけを返す。 */
export function* documentedArguments(
  words: readonly WordNode[],
  parameters: readonly ParameterDoc[],
  isUncertain: (word: WordNode) => boolean,
): Generator<DocumentedArgument> {
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
  const rest = parameters.find((parameter) => parameter.kind === 'restParameterDoc');
  const lastPosition = [...positional.keys()].reduce(
    (maximum, position) => Math.max(maximum, position),
    0,
  );
  let position = 0;
  let positionUnknown = false;

  for (const word of words) {
    const key = namedKey(word);

    if (key !== null) {
      const parameter = named.get(key);

      if (parameter) {
        yield { word, parameter, key, uncertain: isUncertain(word) };
        continue;
      }
    }

    if (positionUnknown) {
      continue;
    }

    position++;
    positionUnknown = isUncertain(word);

    const parameter = positional.get(position) ?? (position > lastPosition ? rest : undefined);

    if (parameter) {
      yield { word, parameter, uncertain: positionUnknown };
    }
  }
}
