import type { FunctionDefinitionNode, SimpleCommandNode, WordNode } from '../zshParser/ast';
import { documentationOf } from '../zshHydrator';
import { namedKey } from '../connection/ast/word';
import type { ParameterDoc } from '../zshHydrator/documentation';
import type { ResolutionContext } from '../diagnostics/calls';
import { uncertainWord } from '../diagnostics/calls';
import { decodeLiteral, literalValue } from './literal';
import type { DecodedLiteral } from './literal';

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
  const last = Math.max(0, ...positional.keys());
  let position = 0;
  let uncertain = false;
  const result: CodeArgument[] = [];
  let remaining = maxText;
  for (const word of command.arguments) {
    const key = namedKey(word);
    let parameter: ParameterDoc | undefined;
    let prefix = 0;
    if (key && named.has(key)) {
      parameter = named.get(key);
      prefix = key.length + 1;
    } else {
      if (uncertain) {
        continue;
      }
      position += 1;
      parameter = positional.get(position) ?? (position > last ? rest : undefined);
      if (uncertainWord(word, context)) {
        uncertain = true;
      }
    }
    if (parameter?.valueType !== 'code' || uncertainWord(word, context)) {
      continue;
    }
    if (word.raw.length > remaining) {
      result.push({ kind: 'limit', word });
      continue;
    }
    remaining -= word.raw.length;
    const decoded = decodeLiteral(word, allowUnterminated);
    if (!decoded) {
      continue;
    }
    const source = literalValue(decoded, prefix);
    if (parameter.literalValues?.includes(source.text)) {
      continue;
    }
    result.push({ kind: 'code', word, source, prefix: decoded.text.slice(0, prefix) });
  }
  return { arguments: result, inspected: maxText - remaining };
}
