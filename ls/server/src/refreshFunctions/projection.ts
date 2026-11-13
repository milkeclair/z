import { pathToFileURL } from 'url';
import { literalWord } from './word';
import type { FunctionTarget, FunctionTargets } from './target';
import type { Result } from '../document/type';
import type { Func, FuncArg } from '../getFunctions/type';
import { NAMED_ARG_POSITION } from '../getFunctions/constant';
import { documentationOf } from '../zshHydrator';
import type { FunctionDocumentation, ParameterDoc, ZshHydrator } from '../zshHydrator';

export function projectFunctions(hydrator: ZshHydrator): {
  readonly functions: Func[]; readonly targets: FunctionTargets;
} {
  const functions: Func[] = [];
  const targets = new Map<string, FunctionTarget[]>();
  for (const entry of hydrator.files.values()) {
    const definitions = new Set(entry.functions.map(fn => fn.definition));
    for (const definition of definitions) {
      const documentation = documentationOf(definition);
      const parameters = documentation?.parameters ?? [];
      const args = parameters.toReversed().map(legacyArgument).sort((left, right) => {
        if (left.isNamed && right.isNamed) return 0;
        if (left.isNamed) return 1;
        if (right.isNamed) return -1;
        return left.position - right.position;
      });
      const view = legacyDocumentation(documentation);
      for (const word of definition.names) {
        const info = { name: word.raw, file: entry.file, line: word.range.start.line + 1,
          args, documentation: view };
        functions.push(info);
        const name = literalWord(word);
        if (!name) continue;
        const target: FunctionTarget = {
          name, uri: pathToFileURL(entry.sourceFile).href, definition, nameNode: word,
          info: { ...info, name },
        };
        const group = targets.get(name) ?? [];
        group.push(target);
        targets.set(name, group);
      }
    }
  }
  return { functions, targets };
}

function legacyArgument(parameter: ParameterDoc): FuncArg {
  const common = { optional: parameter.optional };
  switch (parameter.kind) {
    case 'positionalParameterDoc':
      return { ...common, position: parameter.position, name: parameter.description, isNamed: false };
    case 'namedParameterDoc':
      return { ...common, position: NAMED_ARG_POSITION, name: parameter.name, isNamed: true };
    case 'restParameterDoc':
      return { ...common, position: Number.MAX_SAFE_INTEGER, name: parameter.parameter, isNamed: false };
  }
}

function legacyDocumentation(documentation: FunctionDocumentation | null): Result {
  return {
    description: documentation?.description.map(line => line.text).join('\n').trim() ?? '',
    parameters: documentation?.parameters.map(parameter => ({
      name: '$' + (parameter.kind === 'positionalParameterDoc' ? parameter.position
        : parameter.kind === 'namedParameterDoc' ? parameter.name : parameter.parameter),
      description: parameter.description,
    })) ?? [],
    reply: documentation?.reply?.text ?? '',
    return: documentation?.returns?.text ?? '',
    example: documentation?.examples.map(example => example.text).join('\n\n') ?? '',
  };
}
