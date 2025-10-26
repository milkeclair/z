import { FuncArg } from '../../getFunctions/type';

export function positionalArgRegex(argName: string): RegExp {
  return new RegExp(`\\$${argName}\\b`);
}

export function variablePatternRegex(argName: string): RegExp {
  return new RegExp(`\\$\\{?${argName}\\}?\\b`);
}

export function providePatternRegex(argName: string): RegExp {
  return new RegExp(`\\b${argName}\\b`);
}

export function argRegex(arg: FuncArg): RegExp {
  const namedRegex = new RegExp(`#\\s*\\$${arg.name}`);
  const positionalRegex = new RegExp(`#\\s*\\$${arg.position}\\b`);

  return arg.isNamed ? namedRegex : positionalRegex;
}
