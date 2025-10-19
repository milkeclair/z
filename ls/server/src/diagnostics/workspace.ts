import fs from 'fs';
import path from 'path';
import { globSync } from 'glob';
import { pathToFileURL } from 'url';
import { TextDocuments, TextDocument, DocumentDiagnosticReportKind } from '../vscode_type';
import { validateTextDocument } from './main';
import { Func } from '../getFunctions/type';
import { workspaceDiagnosticsReport } from './type';

export function workspaceDiagnostics({
  projectRoot,
  documents,
  functions,
}: {
  projectRoot: string;
  documents: TextDocuments<TextDocument>;
  functions: Func[];
}): workspaceDiagnosticsReport {
  if (projectRoot === '') return { items: [] };

  const files = globSync('**/*.zsh', { cwd: projectRoot });
  const workspaceDiagnostics: workspaceDiagnosticsReport['items'] = [];

  for (const file of files) {
    const filePath = path.join(projectRoot, file);
    const fileUri = pathToFileURL(filePath).toString();

    let document = documents.get(fileUri);

    if (!document) {
      try {
        const content = fs.readFileSync(filePath, 'utf-8');
        document = TextDocument.create(fileUri, 'zsh', 1, content);
      } catch (error) {
        continue;
      }
    }

    const diagnostics = validateTextDocument({ functions, textDocument: document });

    workspaceDiagnostics.push({
      uri: fileUri,
      version: document.version,
      kind: DocumentDiagnosticReportKind.Full,
      items: diagnostics,
    });
  }

  return { items: workspaceDiagnostics };
}
