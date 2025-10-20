import { DiagnosticSeverity, DocumentDiagnosticReportKind } from '../vscode_type';

export type Diagnostics = {
  severity: DiagnosticSeverity;
  range: {
    start: { line: number; character: number };
    end: { line: number; character: number };
  };
  message: string;
  source: string;
};

export type workspaceDiagnosticsReport = {
  items: {
    uri: string;
    version: number | null;
    kind: typeof DocumentDiagnosticReportKind.Full;
    items: Diagnostics[];
  }[];
};
