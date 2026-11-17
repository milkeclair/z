import { pathToFileURL } from 'url';
import type { Result } from '../document/type';
import { NAMED_ARG_POSITION } from '../getFunctions/constant';
import type { Func, FuncArg } from '../getFunctions/type';
import type {
  FunctionDocumentation,
  ParameterDoc,
  ZshFileHydration,
  ZshHydrator,
} from '../zshHydrator';
import { documentationOf } from '../zshHydrator';
import type { FunctionTarget, FunctionTargets } from './target';
import { literalWord } from './word';

type FunctionProjection = {
  readonly functions: readonly Func[];
  readonly targets: FunctionTargets;
};

export type FileFunctionProjections = ReadonlyMap<ZshFileHydration, FunctionProjection>;

/** 現在のファイル単位の変換結果を再利用し、hydratorの順序で候補を統合する。 */
export function projectFunctions(
  hydrator: ZshHydrator,
  previous: FileFunctionProjections = new Map(),
): FunctionProjection & {
  readonly fileProjections: FileFunctionProjections;
} {
  const entries: readonly (readonly [ZshFileHydration, FunctionProjection])[] = [
    ...hydrator.files.values(),
  ]
    .filter((entry) => entry.functions.length > 0)
    .map((entry) => [entry, previous.get(entry) ?? projectFileFunctions(entry)]);
  const projections = entries.map(([, projection]) => projection);
  const targets = projections.flatMap((projection) => [...projection.targets.values()].flat());

  return {
    functions: projections.flatMap((projection) => projection.functions),
    targets: Map.groupBy(targets, (target) => target.name),
    fileProjections: new Map(entries),
  };
}

/** 情報を付加した1ファイルから、互換用の情報と定義の参照先を取り出す。 */
export function projectFileFunctions(entry: ZshFileHydration): FunctionProjection {
  const uri = pathToFileURL(entry.sourceFile).href;
  const definitions = new Set(entry.functions.map((fn) => fn.definition));
  const projected = [...definitions].flatMap((definition) => {
    const documentation = documentationOf(definition);
    const args = (documentation?.parameters ?? [])
      .toReversed()
      .map(legacyArgument)
      .toSorted((left, right) => {
        if (left.isNamed && right.isNamed) return 0;
        if (left.isNamed) return 1;
        if (right.isNamed) return -1;
        return left.position - right.position;
      });
    const view = legacyDocumentation(documentation);

    return definition.names.map((word) => {
      const info = {
        name: word.raw,
        file: entry.file,
        line: word.range.start.line + 1,
        args,
        documentation: view,
      } satisfies Func;
      const name = literalWord(word);
      const target: FunctionTarget | null = name
        ? { name, uri, definition, nameNode: word, info: { ...info, name } }
        : null;

      return { info, target };
    });
  });
  const targets = projected.flatMap(({ target }) => (target ? [target] : []));

  return {
    functions: projected.map(({ info }) => info),
    targets: Map.groupBy(targets, (target) => target.name),
  };
}

function legacyArgument(parameter: ParameterDoc): FuncArg {
  const common = {
    optional: parameter.optional,
    ...(parameter.valueType ? { valueType: parameter.valueType } : {}),
    ...(parameter.literalValues ? { literalValues: parameter.literalValues } : {}),
  };

  switch (parameter.kind) {
    case 'positionalParameterDoc':
      return {
        ...common,
        position: parameter.position,
        name: parameter.description,
        isNamed: false,
      };
    case 'namedParameterDoc':
      return { ...common, position: NAMED_ARG_POSITION, name: parameter.name, isNamed: true };
    case 'restParameterDoc':
      return {
        ...common,
        position: Number.MAX_SAFE_INTEGER,
        name: parameter.parameter,
        isNamed: false,
      };
  }
}

function legacyDocumentation(documentation: FunctionDocumentation | null): Result {
  return {
    description:
      documentation?.description
        .map((line) => line.text)
        .join('\n')
        .trim() ?? '',
    parameters:
      documentation?.parameters.map((parameter) => ({
        name:
          '$' +
          (parameter.kind === 'positionalParameterDoc'
            ? parameter.position
            : parameter.kind === 'namedParameterDoc'
              ? parameter.name
              : parameter.parameter),
        description: parameter.description,
      })) ?? [],
    reply: documentation?.reply?.text ?? '',
    return: documentation?.returns?.text ?? '',
    example: documentation?.examples.map((example) => example.text).join('\n\n') ?? '',
  };
}
