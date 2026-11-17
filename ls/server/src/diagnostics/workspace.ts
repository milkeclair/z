import { makeSet } from '../util/collections';
import { DocumentDiagnosticReportKind } from '../vscode_type';
import type { DiagnosticSnapshot } from './snapshot';
import type { WorkspaceDiagnosticsReport } from './type';

type ReportItem = WorkspaceDiagnosticsReport['items'][number];

export function workspaceDiagnostics({
  diagnostics,
  previousResultIds = [],
}: {
  readonly diagnostics: DiagnosticSnapshot;
  readonly previousResultIds?: readonly {
    readonly uri: string;
    readonly value: string;
  }[];
}): WorkspaceDiagnosticsReport {
  const current = [...diagnostics.files].flatMap(([uri, file]): readonly ReportItem[] =>
    file.project
      ? [
          {
            uri,
            version: file.version,
            resultId: file.resultId,
            kind: DocumentDiagnosticReportKind.Full,
            items: [...file.items],
          },
        ]
      : [],
  );
  const reported = new Set(current.map((item) => item.uri));
  const removed = [...makeSet(previousResultIds.map((previous) => previous.uri))].filter(
    (uri) => !reported.has(uri),
  );

  return {
    items: [
      ...current,
      ...[...removed].map((uri): ReportItem => ({
        uri,
        version: null,
        kind: DocumentDiagnosticReportKind.Full,
        items: [],
      })),
    ],
  };
}
