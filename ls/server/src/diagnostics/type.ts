import type { DiagnosticSeverity, DocumentDiagnosticReportKind } from '../vscode_type';

export type Diagnostics = {
  readonly severity: DiagnosticSeverity;
  readonly code?: string;
  readonly range: {
    readonly start: { readonly line: number; readonly character: number };
    readonly end: { readonly line: number; readonly character: number };
  };
  readonly message: string;
  readonly source: string;
};

export type workspaceDiagnosticsReport = {
  items: {
    uri: string;
    version: number | null;
    kind: typeof DocumentDiagnosticReportKind.Full;
    items: Diagnostics[];
  }[];
};
