import { CompletionItem } from '../vscode_type';

export function zCompletionResolve(result: CompletionItem): CompletionItem {
  if (result.data && result.data.file) {
    const details = `${result.data.file}:${result.data.line}`;
    const documentation = `defined in ${result.data.file}:${result.data.line}`;

    result.detail = details;
    result.documentation = documentation;
  }

  return result;
}
