import type { CodeProgram } from '../embeddedCode';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import type { TextDocument, TextDocuments } from '../vscode_type';

export type LanguageFeatureRequest<Params> = {
  readonly params: Params;
  readonly documents: Pick<TextDocuments<TextDocument>, 'get'>;
  readonly snapshot: FunctionSnapshot;
  readonly programs?: readonly CodeProgram[];
};

export type HoverContent = {
  readonly contents: {
    kind: 'markdown';
    value: string;
  };
};
