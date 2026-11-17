import type { SimpleCommandSemantic } from '../../../../../../../../ast';
import type { SimpleCommandSemanticInput } from '../types';
import { createDeclarationSemantic } from './declaration';
import { createSourceSemantic } from './source';

export function createSimpleCommandSemantic(
  parts: SimpleCommandSemanticInput,
): SimpleCommandSemantic {
  const source = createSourceSemantic(parts);

  if (source) {
    return source;
  } else {
    const declaration = createDeclarationSemantic(parts);

    if (declaration) {
      return declaration;
    } else {
      return { role: 'normal' };
    }
  }
}
