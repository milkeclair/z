import type { BaseNode } from '../base';
import type { ParserDiagnosticKind } from '../diagnostic';

export type UnknownNode = BaseNode<'unknown'> & {
  readonly reason: ParserDiagnosticKind;
};
