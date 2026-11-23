import type { FunctionTargets } from '../refreshFunctions/target';
import { documentationOf } from '../zshHydrator';
import type { ParameterDoc } from '../zshHydrator/documentation/types';

function sameParameter(left: ParameterDoc, right: ParameterDoc): boolean {
  if (
    left.kind !== right.kind ||
    left.optional !== right.optional ||
    left.valueType !== right.valueType ||
    left.classReference?.className !== right.classReference?.className ||
    left.classReference?.access !== right.classReference?.access
  ) {
    return false;
  }

  const literals = new Set(left.literalValues ?? []);
  const otherLiterals = new Set(right.literalValues ?? []);

  if (
    literals.size !== otherLiterals.size ||
    ![...literals].every((value) => otherLiterals.has(value))
  ) {
    return false;
  }

  switch (left.kind) {
    case 'positionalParameterDoc':
      return right.kind === left.kind && left.position === right.position;
    case 'namedParameterDoc':
      return right.kind === left.kind && left.name === right.name;
    case 'restParameterDoc':
      return right.kind === left.kind && left.parameter === right.parameter;
  }
}

// 未編集の呼び出し元は候補の順序・URI・引数の契約に依存する。定義の
// オフセットと説明文は現在のproviderのsnapshotに属し、診断には含めない。
// 関連する定義位置を診断に追加する場合は、その位置も比較に含める。
export function sameCallContracts(left: FunctionTargets, right: FunctionTargets): boolean {
  if (left === right) {
    return true;
  }

  if (left.size !== right.size) {
    return false;
  }

  return [...left].every(([name, candidates]) => {
    const next = right.get(name);

    return (
      next !== undefined &&
      candidates.length === next.length &&
      candidates.every((target, index) => {
        const other = next[index];

        if (!target || !other || target.name !== other.name || target.uri !== other.uri) {
          return false;
        }

        if (target.definition === other.definition) {
          return true;
        }

        const parameters = documentationOf(target.definition)?.parameters ?? [];
        const nextParameters = documentationOf(other.definition)?.parameters ?? [];

        return (
          parameters.length === nextParameters.length &&
          parameters.every((parameter, position) => {
            const otherParameter = nextParameters[position];

            return otherParameter !== undefined && sameParameter(parameter, otherParameter);
          })
        );
      })
    );
  });
}
