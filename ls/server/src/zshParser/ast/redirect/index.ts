import type { HereDocumentNode } from './hereDocument';
export type { HereDocumentNode } from './hereDocument';
import type { BaseNode } from '../base';
import type { WordNode } from '../word';

export type RedirectNode = BaseNode<'redirect'> & {
  readonly operator: string;
  readonly target: WordNode | null;
  readonly hereDocument: HereDocumentNode | null;
};
