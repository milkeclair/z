import { afterEach, describe, expect, test } from 'vitest';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { zCompletion } from '../../src/connection/completion';
import { zDefinition } from '../../src/connection/definition';
import { emptyShellEnvironment } from '../../src/diagnostics/environment';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { validateTextDocument } from '../../src/diagnostics/main';
import { writeClassApi } from '../support/classApi';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();
const publicCommands = [
  'z.cls.abort',
  'z.cls.attr',
  'z.cls.delete',
  'z.cls.draw',
  'z.cls.drew',
  'z.cls.method',
  'z.cls.method.defined',
  'z.cls.new',
];

afterEach(() => {
  temporaryDirectories.cleanup();
});

/** 実際のクラス宣言を通常のprovider snapshot経由で索引化する。 */
function fixture(content = 'z.cls.¦\n') {
  const root = temporaryDirectories.create('z-class-api-');
  const definitionPath = writeClassApi(root, true);
  const offset = content.indexOf('¦');
  if (offset < 0) throw new Error('Expected a cursor marker');

  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    content.replace('¦', ''),
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const documents = { get: (uri: string) => (uri === document.uri ? document : undefined) };
  const params = { textDocument: { uri: document.uri }, position: document.positionAt(offset) };

  return {
    definitionUri: pathToFileURL(definitionPath).href,
    document,
    snapshot,
    documents,
    params,
  };
}

function privateCommand(name: string): boolean {
  return name.split('.').some((segment) => segment.startsWith('_'));
}

describe('zCompletion', () => {
  describe('公開されたクラスAPIを補完する場合', () => {
    test('通常の補完は公開DSLを表示し、内部関数を隠す', () => {
      const scenario = fixture();
      const items = zCompletion({ ...scenario, showPrivateFunctions: false });

      const names = items?.map((item) => item.label) ?? [];
      expect(names).toEqual(expect.arrayContaining(publicCommands));
      expect(names.filter(privateCommand)).toEqual([]);
    });

    test('private表示を有効にすると公開DSLと内部関数を参照できる', () => {
      const scenario = fixture();
      const names =
        zCompletion({ ...scenario, showPrivateFunctions: true })?.map((item) => item.label) ?? [];
      const internal = names.filter(privateCommand);

      expect(names).toEqual(expect.arrayContaining(publicCommands));
      expect(internal).toContain('z.cls.instance._resolve');
      expect(internal).toContain('z.cls.capture._start');
      expect(names).not.toContain('z.cls.instance.call');
    });
  });
});

describe('zDefinition', () => {
  describe('補完で隠すクラス内部関数を明示した場合', () => {
    test('明示した内部関数の定義へ移動する', () => {
      const scenario = fixture('z.cls.instance._¦resolve reference\n');
      const diagnostics = refreshDiagnosticSnapshot({
        snapshot: scenario.snapshot,
        environment: emptyShellEnvironment(),
      });

      expect(validateTextDocument({ diagnostics, textDocument: scenario.document })).toEqual([]);
      expect(zDefinition(scenario)?.uri).toBe(scenario.definitionUri);
    });
  });
});

describe('validateTextDocument', () => {
  describe('実際の関数コメントでクラス宣言を診断する場合', () => {
    test('実際の属性APIがdefaultの省略を必須引数として診断する', () => {
      const scenario = fixture(
        ['z.cls.draw MissingDefault', '  z.cls.attr price¦', '  z.cls.drew', ''].join('\n'),
      );
      const diagnostics = refreshDiagnosticSnapshot({
        snapshot: scenario.snapshot,
        environment: emptyShellEnvironment(),
      });
      const items = validateTextDocument({ diagnostics, textDocument: scenario.document });

      expect(items.filter((item) => item.code === 'missing-named-argument')).toMatchObject([
        {
          code: 'missing-named-argument',
          message: 'Missing required named argument: default',
        },
      ]);
    });
  });
});
