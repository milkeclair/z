import * as Immutable from 'immutable';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { zCompletion } from '../../src/connection/completion';
import { zCompletionResolve } from '../../src/connection/completionResolve';
import { zDefinition } from '../../src/connection/definition';
import { zHover } from '../../src/connection/hover';
import { zSignatureHelp } from '../../src/connection/signatureHelp';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { Lexer } from '../../src/zshParser/lexer';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

const definition = [
  '# Greeting',
  '# $1: first',
  '# $2?: second',
  '# $@: tail',
  '# $one: option one',
  '# $two?: option two',
  '  function greet { : }',
  '',
].join('\n');

function createLanguageFeatureRequest(source: string, definitions = definition) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-provider-'));
  temporaryDirectories.track(root);
  const definitionUri = pathToFileURL(path.join(root, '日本語 name.zsh')).href;
  fs.writeFileSync(path.join(root, '日本語 name.zsh'), definitions);
  const offset = source.indexOf('¦');

  if (offset < 0) {
    throw new Error('cursor required');
  }

  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    source.replace('¦', ''),
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const documents = { get: (uri: string) => (uri === document.uri ? document : undefined) };
  const params = { textDocument: { uri: document.uri }, position: document.positionAt(offset) };

  return {
    snapshot,
    document,
    definitionUri,
    params,
    documents,
    showPrivateFunctions: true,
  };
}

afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
});

describe('zCompletion', () => {
  describe('カーソル位置から補完する場合', () => {
    test('引用のないコマンド名全体を置き換える', () => {
      const source = 'gr¦eet';

      const result = zCompletion(createLanguageFeatureRequest(source));

      expect(result).toHaveLength(1);
      expect(result?.[0]).toMatchObject({
        label: 'greet',
        textEdit: {
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: source.length - 1 },
          },
          newText: 'greet',
        },
      });
    });

    test('二重引用されたコマンド名全体を置き換える', () => {
      const source = '"gr¦eet"';

      const result = zCompletion(createLanguageFeatureRequest(source));

      expect(result).toHaveLength(1);
      expect(result?.[0]).toMatchObject({
        label: 'greet',
        textEdit: {
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: source.length - 1 },
          },
          newText: 'greet',
        },
      });
    });

    test('単引用されたコマンド名全体を置き換える', () => {
      const source = "'gr¦eet'";

      const result = zCompletion(createLanguageFeatureRequest(source));

      expect(result).toHaveLength(1);
      expect(result?.[0]).toMatchObject({
        label: 'greet',
        textEdit: {
          range: {
            start: { line: 0, character: 0 },
            end: { line: 0, character: source.length - 1 },
          },
          newText: 'greet',
        },
      });
    });

    test('空の文書のコマンド位置で補完する', () => {
      const source = '¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('字下げの後のコマンド位置で補完する', () => {
      const source = '  ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('空行と字下げの後で補完する', () => {
      const source = '\n  ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('セミコロンの後の空位置で補完する', () => {
      const source = 'print x; ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('パイプの後の空位置で補完する', () => {
      const source = 'print x | ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('論理積の後の空位置で補完する', () => {
      const source = 'true && ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('グループ冒頭の空位置で補完する', () => {
      const source = '{ ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('サブシェル冒頭の空位置で補完する', () => {
      const source = '( ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('ifの条件冒頭で補完する', () => {
      const source = 'if ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('then節の冒頭で補完する', () => {
      const source = 'if true; then ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('whileの条件冒頭で補完する', () => {
      const source = 'while ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('for本体の冒頭で補完する', () => {
      const source = 'for x in y; do ¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('コマンド置換の冒頭で補完する', () => {
      const source = 'print "$(¦)"';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('コマンド置換内の空白後で補完する', () => {
      const source = 'print "$(  ¦)"';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion?.map((item) => item.label)).toContain('greet');
    });

    test('通常の引数では関数候補を出さない', () => {
      const source = 'print gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('文字列内では関数候補を出さない', () => {
      const source = 'print "gr¦"';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('コメント内では関数候補を出さない', () => {
      const source = '# gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('リダイレクト先では関数候補を出さない', () => {
      const source = 'print > gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('代入の値では関数候補を出さない', () => {
      const source = 'value=gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('forの列挙値では関数候補を出さない', () => {
      const source = 'for x in gr¦; do :; done';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('caseのパターンでは関数候補を出さない', () => {
      const source = 'case x in gr¦) :;; esac';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('条件式では関数候補を出さない', () => {
      const source = '[[ gr¦ ]]';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('算術式では関数候補を出さない', () => {
      const source = '(( gr¦ ))';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('forのdoの位置では関数候補を出さない', () => {
      const source = 'for x in y\n ¦do :; done';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('caseのパターン開始位置では関数候補を出さない', () => {
      const source = 'case x in\n ¦x) :;; esac';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('builtin指定では関数候補を出さない', () => {
      const source = 'builtin gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('command指定では関数候補を出さない', () => {
      const source = 'command gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('ヒアドキュメント本文では関数候補を出さない', () => {
      const source = 'print <<END\ngr¦\nEND';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('変数参照では関数候補を出さない', () => {
      const source = '$gr¦';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('コマンド置換の引数では関数候補を出さない', () => {
      const source = 'print "x$(print gr¦)"';

      const request = createLanguageFeatureRequest(source);

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('複数行のcommand wordには不正なcompletion editを返さない', () => {
      const request = createLanguageFeatureRequest('gr' + String.fromCharCode(92) + '\\ne¦et');

      const completion = zCompletion(request);

      expect(completion).toEqual([]);
    });

    test('substitution内部のcommandを探索する', () => {
      const request = createLanguageFeatureRequest('print "$(gr¦)"');

      const completion = zCompletion(request);

      expect(completion?.[0].label).toBe('greet');
    });

    test('静的な引用名を索引化し、挿入時に引用する', () => {
      const request = createLanguageFeatureRequest('¦', "function 'hello world' 'if' { : }\n");

      const completion = zCompletion(request);

      expect(completion?.map((item) => [item.label, item.textEdit])).toMatchObject([
        ['hello world', { newText: "'hello world'" }],
        ['if', { newText: "'if'" }],
      ]);
    });

    test('glob・引用符・modifier名はリテラルとして挿入する', () => {
      const quoted = "'a'" + String.fromCharCode(92) + "''b'";
      const request = createLanguageFeatureRequest(
        '¦',
        "function 'hello?' command " + quoted + ' { : }',
      );

      const completion = zCompletion(request);

      expect(completion?.map((item) => [item.label, item.textEdit?.newText])).toEqual([
        ['hello?', "'hello?'"],
        ['command', "'command'"],
        ["a'b", quoted],
      ]);
    });

    test('resolveは現在のsnapshotの文書情報を使い、入力itemを変更しない', () => {
      const request = createLanguageFeatureRequest('gr¦');
      const item = zCompletion(request)?.[0];

      if (!item) {
        throw new Error('completion required');
      }

      const resolved = zCompletionResolve(item, request.snapshot);

      expect(item.documentation).toBeUndefined();
      expect(resolved.documentation).toMatchObject({ value: expect.stringContaining('Greeting') });
      expect(zCompletionResolve({ label: 'greet', data: { uri: 1 } }, request.snapshot)).toEqual({
        label: 'greet',
        data: { uri: 1 },
      });
    });
  });

  describe('キャッシュ済みの解析結果を利用する場合', () => {
    test('要求処理は文書を再解析せず、同じsnapshotを参照する', () => {
      const request = createLanguageFeatureRequest('gr¦eet');
      const spy = vi.spyOn(Lexer, 'tokenize');

      for (const attempt of Immutable.Range(0, 10)) {
        const item = zCompletion(request)?.[0];

        const definition = zDefinition(request);

        expect(definition?.uri).toBe(request.definitionUri);
        const hover = zHover(request);

        expect(hover).not.toBeNull();
        zSignatureHelp(request);

        if (item) {
          zCompletionResolve(item, request.snapshot);
        }
      }

      expect(spy).not.toHaveBeenCalled();
    });

    test('未反映のversionには古いASTを返さない', () => {
      const request = createLanguageFeatureRequest('gr¦eet');
      const changedDocument = TextDocument.create(request.document.uri, 'shellscript', 2, 'other');
      const changedRequest = {
        ...request,
        documents: {
          get: (uri: string) => (uri === changedDocument.uri ? changedDocument : undefined),
        },
      };

      const hover = zHover(changedRequest);

      expect(hover).toBeNull();
      const definition = zDefinition(changedRequest);

      expect(definition).toBeNull();
      const completion = zCompletion(changedRequest);

      expect(completion).toEqual([]);
    });
  });
});
