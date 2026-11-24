import { castDraft } from 'immer';
import { produce } from '../util/collections';
import type { ResolutionContext } from '../diagnostics/calls';
import { uncertainWord } from '../diagnostics/calls';
import { documentationOf } from '../zshHydrator';
import { documentedArguments } from '../zshHydrator/documentation/arguments';
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

  const initial: {
    readonly arguments: readonly CodeArgument[];
    readonly inspected: number;
  } = { arguments: [], inspected: 0 };
  const matches = documentedArguments(command.arguments, parameters, (word) =>
    uncertainWord(word, context),
  );

  return produce(initial, (draft) => {
    for (const { word, parameter, key, uncertain } of matches) {
      if (parameter.valueType !== 'code' || uncertain) continue;

      if (word.raw.length > maxText - draft.inspected) {
        draft.arguments.push(castDraft({ kind: 'limit', word }));
        continue;
      }

      draft.inspected += word.raw.length;
      const decoded = decodeLiteral(word, allowUnterminated);
      if (!decoded) continue;

      const prefix = key ? key.length + 1 : 0;
      const source = literalValue(decoded, prefix);

      if (!parameter.literalValues?.includes(source.text)) {
        draft.arguments.push(
          castDraft({ kind: 'code', word, source, prefix: decoded.text.slice(0, prefix) }),
        );
      }
    }
  });
}
