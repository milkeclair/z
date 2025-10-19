import path from 'path';
import { fileURLToPath } from 'url';
import { TextDocuments, TextDocument } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { getAllZFunctions, extractZFunctions } from '../getFunctions/main';

export const refreshFunctions = ({
  projectRoot,
  documents,
}: {
  projectRoot: string;
  documents: TextDocuments<TextDocument>;
}): Func[] => {
  if (projectRoot === '') return [];

  const baseFunctions = getAllZFunctions(projectRoot);
  const overrideFiles = new Set<string>();
  const overrideFunctions: Func[] = [];

  for (const document of documents.all()) {
    if (!document.uri.endsWith('.zsh')) continue;

    const absolutePath = path.resolve(fileURLToPath(document.uri));
    const relativePath = path.relative(projectRoot, absolutePath);
    if (relativePath === '') continue;

    const newFunctions = extractZFunctions(document.getText()).map((f) => ({
      name: f.name,
      line: f.line,
      file: relativePath,
    }));

    overrideFiles.add(relativePath);
    overrideFunctions.push(...newFunctions);
  }

  const withoutOverrides = baseFunctions.filter((f) => !overrideFiles.has(f.file));

  return withoutOverrides.concat(overrideFunctions);
};
