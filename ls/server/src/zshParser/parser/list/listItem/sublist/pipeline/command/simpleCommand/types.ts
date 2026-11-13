import type {
  AssignNode,
  CommandNameNode,
  PrecommandModifierNode,
  RedirectNode,
  WordNode,
} from '../../../../../../../ast';
import type { ParseState } from '../../../../../../state';

export type SimpleCommandSemanticInput = {
  readonly precommandModifiers: readonly PrecommandModifierNode[];
  readonly prefixAssignments: readonly AssignNode[];
  readonly commandName: CommandNameNode | null;
  readonly arguments: readonly WordNode[];
  readonly redirects: readonly RedirectNode[];
};

export type SimpleCommandAccumulator = SimpleCommandSemanticInput & {
  readonly state: ParseState;
  readonly startIndex: number;
  readonly syntaxEndIndex: number;
};
