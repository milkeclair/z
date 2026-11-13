import type { FunctionTargets } from '../refreshFunctions/target';
import { documentationOf } from '../zshHydrator';
import type { ParameterDoc } from '../zshHydrator/documentation/types';

function sameParameter(left: ParameterDoc, right: ParameterDoc): boolean {
  if (left.kind !== right.kind || left.optional !== right.optional) return false;
  switch (left.kind) {
    case 'positionalParameterDoc':
      return right.kind === left.kind && left.position === right.position;
    case 'namedParameterDoc':
      return right.kind === left.kind && left.name === right.name;
    case 'restParameterDoc':
      return right.kind === left.kind && left.parameter === right.parameter;
  }
}

// Unedited callers depend on candidate order/URI and parameter contracts. Declaration
// offsets and descriptions belong to the current provider snapshot, not their diagnostics.
// If diagnostics gain related definition locations, those must join this comparison.
export function sameCallContracts(left: FunctionTargets, right: FunctionTargets): boolean {
  if (left === right) return true;
  if (left.size !== right.size) return false;
  for (const [name, candidates] of left) {
    const next = right.get(name);
    if (!next || candidates.length !== next.length) return false;
    for (let index = 0; index < candidates.length; index++) {
      const target = candidates[index];
      const other = next[index];
      if (!target || !other || target.name !== other.name || target.uri !== other.uri) return false;
      if (target.definition === other.definition) continue;
      const parameters = documentationOf(target.definition)?.parameters ?? [];
      const nextParameters = documentationOf(other.definition)?.parameters ?? [];
      if (parameters.length !== nextParameters.length ||
        !parameters.every((parameter, position) => {
          const nextParameter = nextParameters[position];
          return nextParameter !== undefined && sameParameter(parameter, nextParameter);
        })) return false;
    }
  }
  return true;
}
