import type { Result } from '../document/type';
import type { Func, FuncArg } from '../getFunctions/type';
import { NAMED_ARG_POSITION } from '../getFunctions/constant';
import { documentationOf } from '../zshHydrator';
import type { FunctionDocumentation, ParameterDoc, ZshHydrator } from '../zshHydrator';

export function functionsFromHydrator(hydrator: ZshHydrator): Func[] {
  return [...hydrator.files.values()].flatMap((entry) => entry.functions.map(({ name, definition }) => {
    const word = definition.names.find((candidate) => candidate.raw === name);
    const documentation = documentationOf(definition);
    const parameters = documentation?.parameters ?? [];
    const args = parameters.toReversed().map(legacyArgument).sort((left, right) => {
      if (left.isNamed && right.isNamed) return 0;
      if (left.isNamed) return 1;
      if (right.isNamed) return -1;
      return left.position - right.position;
    });
    return { name, file: entry.file, line: (word?.range.start.line ?? definition.range.start.line) + 1,
      args, documentation: legacyDocumentation(documentation) };
  }));
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
