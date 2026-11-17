import type { Result } from '../document/type';
import type { CodeSourceMap } from '../embeddedCode/sourceMap';
import { codeRange } from '../embeddedCode/sourceMap';
import type { Func } from '../getFunctions/type';
import type { FunctionDefinitionNode, WordNode } from '../zshParser/ast';

export type FunctionTarget = {
  readonly name: string;
  readonly uri: string;
  readonly definition: FunctionDefinitionNode;
  readonly nameNode: WordNode;
  readonly info: Func & { documentation: Result };
  readonly source?: CodeSourceMap;
};
export type FunctionTargets = ReadonlyMap<string, readonly FunctionTarget[]>;

/** 埋め込みコードの定義位置を元の文書へ戻す。 */
export function targetRange(target: FunctionTarget) {
  return target.source ? codeRange(target.source, target.nameNode.range) : target.nameNode.range;
}
