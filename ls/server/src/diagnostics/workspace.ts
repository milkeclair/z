import { DocumentDiagnosticReportKind } from '../vscode_type';
import type { workspaceDiagnosticsReport } from './type';
import type { DiagnosticSnapshot } from './snapshot';

export function workspaceDiagnostics({ diagnostics, previousResultIds = [] }: {
  readonly diagnostics: DiagnosticSnapshot;
  readonly previousResultIds?: readonly { readonly uri: string; readonly value: string }[];
}): workspaceDiagnosticsReport {
  const items: workspaceDiagnosticsReport['items'] = [];
  const reported = new Set<string>();
  for (const [uri, file] of diagnostics.files) {
    if (!file.project) continue;
    reported.add(uri);
    items.push({ uri, version: file.version, resultId: file.resultId, kind: DocumentDiagnosticReportKind.Full, items: [...file.items] });
  }
  for (const previous of previousResultIds) {
    if (!reported.has(previous.uri)) {
      reported.add(previous.uri);
      items.push({ uri: previous.uri, version: null, kind: DocumentDiagnosticReportKind.Full, items: [] });
    }
  }
  return { items };
}
