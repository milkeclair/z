import type { SimpleCommandSemantic } from '../../../../../../../../ast';
import type { SimpleCommandSemanticInput } from '../types';

const Dot = '.';
const Source = 'source';

export function createSourceSemantic(
  parts: SimpleCommandSemanticInput,
): SimpleCommandSemantic | null {
  const value = parts.commandName?.value;

  if (value === Source || value === Dot) {
    return {
      role: 'source',
      source: {
        form: value === Source ? 'source' : 'dot',
        target: parts.arguments[0] ?? null,
      },
    };
  } else {
    return null;
  }
}
