import { DiagnosticSeverity } from 'vscode-languageserver';

export type Diagnostics = {
  severity: typeof DiagnosticSeverity.Error;
  range: {
    start: { line: number; character: number };
    end: { line: number; character: number };
  };
  message: string;
  source: string;
};
