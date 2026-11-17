import { numberRange } from '../../src/util/collections';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { commandInsertion } from '../../src/connection/ast/word';
import { zCompletion } from '../../src/connection/completion';
import { zCompletionResolve } from '../../src/connection/completionResolve';
import { zDefinition } from '../../src/connection/definition';
import { zHover } from '../../src/connection/hover';
import { zSignatureHelp } from '../../src/connection/signatureHelp';
import { emptyShellEnvironment } from '../../src/diagnostics/environment';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { decodeLiteral, literalValue } from '../../src/embeddedCode/literal';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { literalWord } from '../../src/refreshFunctions/word';
import { createZshFileHydration } from '../../src/zshHydrator';
import { findAll } from '../../src/zshParser/ast';
import { Lexer } from '../../src/zshParser/lexer';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
});

const definitions = [
  "# $code? [code | 'noop']: commands",
  'run_code() { : }',
  '# Greeting',
  '# $1: value',
  'greet() { : }',
  "function 'hello world' { : }",
  '',
].join('\n');

function createLanguageFeatureRequest(
  source: string,
  outside = false,
  extraDefinitions: readonly string[] = [],
) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-code-provider-'));
  temporaryDirectories.track(root);
  const definitionUri = pathToFileURL(path.join(root, 'definition.zsh')).href;
  fs.writeFileSync(path.join(root, 'definition.zsh'), definitions + extraDefinitions.join('\n'));
  const offset = source.indexOf('¦');

  if (offset < 0) {
    throw new Error('cursor required');
  }

  const sourceFile = outside
    ? path.join(path.dirname(root), path.basename(root) + '-outside.zsh')
    : path.join(root, 'caller.zsh');
  const document = TextDocument.create(
    pathToFileURL(sourceFile).href,
    'shellscript',
    1,
    source.replace('¦', ''),
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: emptyShellEnvironment() });
  const programs = diagnostics.files.get(document.uri)?.codePrograms ?? [];
  const documents = { get: (uri: string) => (uri === document.uri ? document : undefined) };
  const params = { textDocument: { uri: document.uri }, position: document.positionAt(offset) };

  return {
    document,
    snapshot,
    programs,
    definitionUri,
    params,
    documents,
    showPrivateFunctions: true,
  };
}

describe('zCompletion', () => {
  describe('コード引数内を編集する場合', () => {
    test('単引用のコード内を元文書へ補完する', () => {
      const source = "run_code code='gr¦'";

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('二重引用のコード内を元文書へ補完する', () => {
      const source = 'run_code code="gr¦"';

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('ANSI引用のコード内を元文書へ補完する', () => {
      const source = "run_code code=$'gr¦'";

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('閉じていない単引用のコード内を補完する', () => {
      const source = "run_code code='gr¦";

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('閉じていない二重引用のコード内を補完する', () => {
      const source = 'run_code code="gr¦';

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('閉じていないANSI引用のコード内を補完する', () => {
      const source = "run_code code=$'gr¦";

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('引数全体を引用したコード内を補完する', () => {
      const source = "run_code 'code=gr¦'";

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('入れ子のコード引数内を補完する', () => {
      const source = 'run_code code="run_code code=\'gr¦\'"';

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('日本語と絵文字を含む複数行のコード内を補完する', () => {
      const source = "print 日本😀; run_code code='print value\ngr¦'";

      const request = createLanguageFeatureRequest(source);
      const item = zCompletion(request)?.find((item) => item.label === 'greet');

      expect(item).toMatchObject({ textEdit: { newText: 'greet' } });

      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }

      const start = request.document.offsetAt(item.textEdit.range.start);
      const end = request.document.offsetAt(item.textEdit.range.end);

      expect(request.document.getText().slice(start, end)).toBe('gr');
      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toMatchObject({
        value: expect.stringContaining('Greeting'),
      });
    });

    test('空のコード文字列から候補を返す', () => {
      const source = "run_code code='¦'";

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('引用符を入力した直後から候補を返す', () => {
      const source = "run_code code='¦";

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('コード内のhover・署名・定義を通常の関数へ接続する', () => {
      const request = createLanguageFeatureRequest("run_code code='gr¦eet value'");

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Greeting') },
      });
      const definition = zDefinition(request);

      expect(definition?.uri).toBe(request.definitionUri);
      const request2 = createLanguageFeatureRequest("run_code code='greet ¦'");

      const signature = zSignatureHelp(request2);

      expect(signature).toMatchObject({
        signatures: [{ label: 'greet $1' }],
        activeParameter: 0,
      });
    });

    test('内側の定義を補完・解決し、元の文字列位置へ定義ジャンプする', () => {
      const source = "run_code code='inner() { : }; in¦ner'";
      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('inner');
      const definition = zDefinition(request);

      expect(definition).toMatchObject({
        uri: request.document.uri,
        range: { start: { line: 0, character: source.indexOf('inner') } },
      });
      const request2 = createLanguageFeatureRequest(source.replace('in¦ner', 'inner') + '\nin¦ner');

      const definition2 = zDefinition(request2);

      expect(definition2).toBeNull();
    });

    test('外側の引用符へ安全に文字列を挿入する', () => {
      for (const source of [
        "run_code code='hello¦'",
        'run_code code="hello¦"',
        "run_code code=$'hello¦'",
        "run_code code='hel'lo¦",
        'run_code code=hello¦',
      ]) {
        const request = createLanguageFeatureRequest(source);
        const item = zCompletion(request)?.find((item) => item.label === 'hello world');

        if (!item?.textEdit || !('range' in item.textEdit)) {
          throw new Error('edit expected');
        }

        const edited = TextDocument.applyEdits(request.document, [item.textEdit]);
        const outer = createZshFileHydration({ sourceFile: 'x', file: 'x', content: edited });

        expect(outer.lexerDiagnostics).toEqual([]);
        const word = findAll(outer.ast, 'simpleCommand')[0].arguments[0];
        const decoded = decodeLiteral(word);

        if (!decoded) {
          throw new Error('literal expected');
        }

        const inner = createZshFileHydration({
          sourceFile: 'x',
          file: 'x',
          content: literalValue(decoded, 5).text,
        });
        const command = findAll(inner.ast, 'simpleCommand')[0];

        if (!command.commandName) {
          throw new Error('command expected');
        }

        expect(literalWord(command.commandName.word)).toBe('hello world');
      }
    });

    test('通常の文字列ではコード補完を行わない', () => {
      const source = "print 'gr¦'";

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('許可値の途中ではコード補完を行わない', () => {
      const source = "run_code code='no¦op'";

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('変数展開の途中ではコード補完を行わない', () => {
      const source = 'run_code code="$gr¦"';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('編集中の要求で同じ埋め込みASTを再利用する', () => {
      const request = createLanguageFeatureRequest("run_code code='gr¦eet value'");
      const spy = vi.spyOn(Lexer, 'tokenize');

      for (const _attempt of numberRange(0, 5)) {
        zCompletion(request);
        zHover(request);
        zDefinition(request);
        zSignatureHelp(request);
      }

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('内側と外側のコードを保持する場合', () => {
    test('workspace外の文書にある定義を、そのコード内だけで解決する', () => {
      const request = createLanguageFeatureRequest(
        "outside_only() { : }; run_code code='out¦side_only'",
        true,
      );

      expect(request.snapshot.targets.has('outside_only')).toBe(false);
      const item = zCompletion(request)?.find((item) => item.label === 'outside_only');

      expect(item).toBeDefined();
      const definition = zDefinition(request);

      expect(definition?.uri).toBe(request.document.uri);

      if (!item) {
        throw new Error('outside completion required');
      }

      expect(
        zCompletionResolve(item, request.snapshot, request.programs).documentation,
      ).toBeDefined();
    });

    test('複数段の引用でも特殊文字を実行可能な展開へ変えず挿入する', () => {
      const names = [
        "a'b",
        'a"b',
        'a\\b',
        '$value',
        '$(never-run)',
        String.fromCharCode(96) + 'never-run' + String.fromCharCode(96),
      ];

      for (const name of names) {
        const extra = ['function ' + commandInsertion(name) + ' { : }\n'];
        const request = createLanguageFeatureRequest(
          'run_code code="run_code code=\'¦\'"',
          false,
          extra,
        );
        const item = zCompletion(request)?.find((item) => item.label === name);

        if (!item?.textEdit || !('range' in item.textEdit)) {
          throw new Error('edit expected: ' + name);
        }

        const initial = TextDocument.applyEdits(request.document, [item.textEdit]);
        const text = numberRange(0, 2).reduce((previous) => {
          const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: previous });

          expect(file.lexerDiagnostics).toEqual([]);
          const argument = findAll(file.ast, 'simpleCommand')[0].arguments[0];
          const decoded = decodeLiteral(argument);

          if (!decoded) {
            throw new Error('outer expansion introduced: ' + name);
          }

          return literalValue(decoded, 5).text;
        }, initial);
        const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: text });
        const word = findAll(file.ast, 'simpleCommand')[0].commandName?.word;

        if (!word) {
          throw new Error('command expected');
        }

        expect(literalWord(word)).toBe(name);
      }
    });

    test('物理的に複数行になる補完編集やカーソルを含まない範囲を返さない', () => {
      const request = createLanguageFeatureRequest(
        'run_code code="gr' + String.fromCharCode(92) + '\nee¦t"',
      );

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
      const request2 = createLanguageFeatureRequest("run_code code='gr''¦'");

      const completion2 = zCompletion(request2);

      expect(completion2).toEqual([]);
    });
  });
});
