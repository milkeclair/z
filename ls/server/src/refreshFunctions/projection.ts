import * as Immutable from 'immutable';
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
  const initial = {
    functions: Immutable.List<Func>(),
    targets: Immutable.OrderedMap<string, Immutable.List<FunctionTarget>>(),
    files: Immutable.OrderedMap<ZshFileHydration, FunctionProjection>(),
  };
  const projected = [...hydrator.files.values()].reduce((previousProjection, entry) => {
    if (entry.functions.length === 0) {
      return previousProjection;
    }

    const projection = previous.get(entry) ?? projectFileFunctions(entry);
    const targets = [...projection.targets].reduce(
      (groups, [name, candidates]) =>
        groups.set(name, (groups.get(name) ?? Immutable.List<FunctionTarget>()).concat(candidates)),
      previousProjection.targets,
    );

    return {
      functions: previousProjection.functions.concat(projection.functions),
      targets,
      files: previousProjection.files.set(entry, projection),
    };
  }, initial);

  return {
    functions: projected.functions.toArray(),
    targets: new Map(projected.targets.map((group) => group.toArray())),
    fileProjections: new Map(projected.files),
  };
}

/** 情報を付加した1ファイルから、互換用の情報と定義の参照先を取り出す。 */
export function projectFileFunctions(entry: ZshFileHydration): FunctionProjection {
  const initial = {
    functions: Immutable.List<Func>(),
    targets: Immutable.OrderedMap<string, Immutable.List<FunctionTarget>>(),
  };
  const projected = Immutable.OrderedSet(entry.functions.map((fn) => fn.definition)).reduce(
    (previous, definition) => {
      const documentation = documentationOf(definition);
      const args = (documentation?.parameters ?? [])
        .toReversed()
        .map(legacyArgument)
        .toSorted((left, right) => {
          if (left.isNamed && right.isNamed) {
            return 0;
          }

          if (left.isNamed) {
            return 1;
          }

          if (right.isNamed) {
            return -1;
          }

          return left.position - right.position;
        });
      const view = legacyDocumentation(documentation);

      return definition.names.reduce((current, word) => {
        const info: Func = {
          name: word.raw,
          file: entry.file,
          line: word.range.start.line + 1,
          args,
          documentation: view,
        };
        const functions = current.functions.push(info);
        const name = literalWord(word);

        if (!name) {
          return { ...current, functions };
        }

        const target: FunctionTarget = {
          name,
          uri: pathToFileURL(entry.sourceFile).href,
          definition,
          nameNode: word,
          info: { ...info, name, documentation: view },
        };
        const group = current.targets.get(name) ?? Immutable.List<FunctionTarget>();

        return { functions, targets: current.targets.set(name, group.push(target)) };
      }, previous);
    },
    initial,
  );

  return {
    functions: projected.functions.toArray(),
    targets: new Map(projected.targets.map((group) => group.toArray())),
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
