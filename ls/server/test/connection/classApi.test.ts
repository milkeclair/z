import { afterEach, describe, expect, test } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { globSync } from 'glob';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { zCompletion } from '../../src/connection/completion';
import { zDefinition } from '../../src/connection/definition';
import { emptyShellEnvironment } from '../../src/diagnostics/environment';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { validateTextDocument } from '../../src/diagnostics/main';

const roots: string[] = [];
const publicCommands = [
  'z.cls.abort', 'z.cls.attr', 'z.cls.delete', 'z.cls.draw',
  'z.cls.drew', 'z.cls.fn', 'z.cls.fn.done', 'z.cls.new',
];

afterEach(() => {
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});

/** Index the actual class declarations through the ordinary provider snapshot path. */
function fixture(content = 'z.cls.¦\n') {
  const repoRoot = path.resolve(__dirname, '../../../..');
  const source = globSync('lib/cls/**/*.zsh', { cwd: repoRoot, nodir: true }).sort()
    .map(file => fs.readFileSync(path.join(repoRoot, file), 'utf8')).join('\n');
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-class-api-'));
  roots.push(root);
  const definitionPath = path.join(root, 'class.zsh');
  fs.writeFileSync(definitionPath, source);
  const offset = content.indexOf('¦');
  if (offset < 0) throw new Error('Expected a cursor marker');

  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href, 'shellscript', 1, content.replace('¦', ''),
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const documents = { get: (uri: string) => uri === document.uri ? document : undefined };
  const params = { textDocument: { uri: document.uri }, position: document.positionAt(offset) };

  return { definitionUri: pathToFileURL(definitionPath).href, document, snapshot, documents, params };
}

describe('class API visibility', () => {
  test('通常の補完は実際の公開DSLの8関数だけを返す', () => {
    const scenario = fixture();
    const items = zCompletion({ ...scenario, showPrivateFunctions: false });

    expect(items?.map(item => item.label).toSorted()).toEqual(publicCommands);
  });

  test('private表示を有効にすると内部20関数も参照できる', () => {
    const scenario = fixture();
    const names = zCompletion({ ...scenario, showPrivateFunctions: true })?.map(item => item.label) ?? [];
    const internal = names.filter(name => name.split('.').some(segment => segment.startsWith('_')));

    expect(names).toHaveLength(28);
    expect(internal).toHaveLength(20);
    expect(internal).toContain('z.cls.instance._call');
    expect(internal).toContain('z.cls.capture._start');
    expect(names).not.toContain('z.cls.instance.call');
  });

  test('明示した内部呼出しは補完の表示設定に関係なく解決する', () => {
    const scenario = fixture('z.cls.instance._¦call reference method member\n');
    const diagnostics = refreshDiagnosticSnapshot({ snapshot: scenario.snapshot, environment: emptyShellEnvironment() });

    expect(validateTextDocument({ diagnostics, textDocument: scenario.document })).toEqual([]);
    expect(zDefinition(scenario)?.uri).toBe(scenario.definitionUri);
  });
});
