import { List } from 'immutable';
import { namedKey } from '../connection/ast/word';
import type { ResolutionContext } from '../diagnostics/calls';
import { uncertainWord } from '../diagnostics/calls';
import { documentationOf } from '../zshHydrator';
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
  | { readonly kind: 'limit'; readonly word: WordNode };

/** 文書でコード型を指定した引数を対応付け、引数の個数が不確かな場合は保留し、復号量を文字数の上限に計上する。 */
export function codeArguments(
  command: SimpleCommandNode,
  target: FunctionDefinitionNode,
  context: ResolutionContext,
  maxText = 1024 * 1024,
  allowUnterminated = false,
): { readonly arguments: readonly CodeArgument[]; readonly inspected: number } {
  const parameters = documentationOf(target)?.parameters ?? [];
  if (!parameters.some((parameter) => parameter.valueType === 'code')) {
    return { arguments: [], inspected: 0 };
  }
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
  const last = [...positional.keys()].reduce((maximum, position) => Math.max(maximum, position), 0);
  const initial = {
    position: 0,
    uncertain: false,
    result: List<CodeArgument>(),
    remaining: maxText,
  };
  const parsed = command.arguments.reduce((previous, word) => {
    const key = namedKey(word);
    if (!(key && named.has(key)) && previous.uncertain) {
      return previous;
    }
    const selected =
      key && named.has(key)
        ? {
            parameter: named.get(key),
            prefix: key.length + 1,
            position: previous.position,
            uncertain: previous.uncertain,
          }
        : {
            parameter:
              positional.get(previous.position + 1) ??
              (previous.position + 1 > last ? rest : undefined),
            prefix: 0,
            position: previous.position + 1,
            uncertain: uncertainWord(word, context),
          };
    const current = { ...previous, position: selected.position, uncertain: selected.uncertain };
    const { parameter, prefix } = selected;
    if (parameter?.valueType !== 'code' || uncertainWord(word, context)) {
      return current;
    }
    if (word.raw.length > current.remaining) {
      return { ...current, result: current.result.push({ kind: 'limit', word }) };
    }
    const bounded = { ...current, remaining: current.remaining - word.raw.length };
    const decoded = decodeLiteral(word, allowUnterminated);
    if (!decoded) {
      return bounded;
    }
    const source = literalValue(decoded, prefix);
    return parameter.literalValues?.includes(source.text)
      ? bounded
      : {
          ...bounded,
          result: bounded.result.push({
            kind: 'code',
            word,
            source,
            prefix: decoded.text.slice(0, prefix),
          }),
        };
  }, initial);
  return { arguments: parsed.result.toArray(), inspected: maxText - parsed.remaining };
}
