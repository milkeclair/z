import { castDraft } from 'immer';
import { makeMap, produce } from '../../util/collections';
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
export function documentedArguments(
  words: readonly WordNode[],
  parameters: readonly ParameterDoc[],
  isUncertain: (word: WordNode) => boolean,
): readonly DocumentedArgument[] {
  const named = makeMap(
    parameters.flatMap((parameter) =>
      parameter.kind === 'namedParameterDoc' ? [[parameter.name, parameter]] : [],
    ),
  );
  const positional = makeMap(
    parameters.flatMap((parameter) =>
      parameter.kind === 'positionalParameterDoc' ? [[parameter.position, parameter]] : [],
    ),
  );
  const rest = parameters.find((parameter) => parameter.kind === 'restParameterDoc');
  const lastPosition = [...positional.keys()].reduce(
    (maximum, position) => Math.max(maximum, position),
    0,
  );
  const initial: {
    readonly nextPosition: number | null;
    readonly matches: readonly DocumentedArgument[];
  } = { nextPosition: 1, matches: [] };

  return produce(initial, (draft) => {
    for (const word of words) {
      const key = namedKey(word);
      const namedParameter = key === null ? undefined : named.get(key);

      if (key !== null && namedParameter) {
        const uncertain = isUncertain(word);
        draft.matches.push(castDraft({ word, parameter: namedParameter, key, uncertain }));
        continue;
      }

      const position = draft.nextPosition;
      if (position === null) continue;

      const uncertain = isUncertain(word);
      draft.nextPosition = uncertain ? null : position + 1;
      const parameter = positional.get(position) ?? (position > lastPosition ? rest : undefined);

      if (parameter) {
        draft.matches.push(castDraft({ word, parameter, uncertain }));
      }
    }
  }).matches;
}
