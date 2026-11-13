import type { FunctionDefinitionNode, WordNode } from '../zshParser/ast';
import type { Func } from '../getFunctions/type';
import type { Result } from '../document/type';

export type FunctionTarget = {
  readonly name: string;
  readonly uri: string;
  readonly definition: FunctionDefinitionNode;
  readonly nameNode: WordNode;
  readonly info: Func & { documentation: Result };
};
export type FunctionTargets = ReadonlyMap<string, readonly FunctionTarget[]>;
