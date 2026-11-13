import type { WordContext } from './part/types';
import type {
  ArithmeticExpansionNode,
  CommandSubstitutionNode,
  ParameterExpansionNode,
} from '../../ast';
import type { SourceRange } from '../../lexer';

export type ExpansionNodeKind =
  | 'parameterExpansion'
  | 'commandSubstitution'
  | 'arithmeticExpansion';

type ExpansionNodeInput = WordContext & {
  readonly kind: ExpansionNodeKind;
  readonly range: SourceRange;
  readonly raw: string;
};

export function createExpansionNode({
  kind,
  range,
  raw,
  readBody,
}: ExpansionNodeInput): ParameterExpansionNode | CommandSubstitutionNode | ArithmeticExpansionNode {
  if (kind === 'parameterExpansion') {
    return {
      kind,
      range,
      raw,
    };
  } else if (kind === 'commandSubstitution') {
    return {
      kind,
      range,
      raw,
      body: readBody?.(raw, range) ?? null,
    };
  } else {
    return {
      kind,
      range,
      raw,
    };
  }
}
