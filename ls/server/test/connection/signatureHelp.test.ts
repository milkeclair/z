import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { zSignatureHelp } from '../../src/connection/signatureHelp';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
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

describe('zSignatureHelp', () => {
  describe('入力中の引数を選ぶ場合', () => {
    test('最初の位置引数を入力中は第1引数を選ぶ', () => {
      const source = 'greet ¦';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('空白を含む引数の後は第2引数を選ぶ', () => {
      const source = 'greet "hello world" ¦';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('改行を含む引数の後は第2引数を選ぶ', () => {
      const source = 'greet "hello\nworld" ¦';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('行継続した引数の後は第2引数を選ぶ', () => {
      const source = 'greet a ' + String.fromCharCode(92) + '\n ¦';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('名前付き引数を位置引数として数えない', () => {
      const source = 'greet one=value ¦';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('入力中の名前付き引数に対応する署名を選ぶ', () => {
      const source = 'greet two=val¦ue';
      const index = 3;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('引用された名前付き引数を位置引数として数えない', () => {
      const source = 'greet "one=value" ¦';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('二重引用された名前付き引数の署名を選ぶ', () => {
      const source = 'greet "two=val¦ue"';
      const index = 3;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('動的な値を持つ名前付き引数の署名を選ぶ', () => {
      const source = 'greet "two=$val¦ue"';
      const index = 3;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('単引用された名前付き引数の署名を選ぶ', () => {
      const source = "greet 'two=val¦ue'";
      const index = 3;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('供給済みの名前付き引数を除いて位置引数を選ぶ', () => {
      const source = 'greet "two=value" one=value ¦';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('名前付き引数の後の位置引数を数える', () => {
      const source = 'greet "two=value" first ¦';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('動的な引数名を静的な名前へ対応付けない', () => {
      const source = 'greet "${key}=val¦ue"';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('途中に展開がある引数名を対応付けない', () => {
      const source = 'greet "tw${key}=val¦ue"';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('改行を含む引数の後は第2引数を選ぶ', () => {
      const source = 'greet "hello\nworld" ¦';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('行継続した引数の後は第2引数を選ぶ', () => {
      const source = 'greet a ' + String.fromCharCode(92) + '\n ¦';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('コマンド置換内の引数位置を選ぶ', () => {
      const source = 'print "$(greet a ¦)"';
      const index = 1;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('パイプ先の呼び出しの引数位置を選ぶ', () => {
      const source = 'print x | greet ¦';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('セミコロン後の呼び出しの引数位置を選ぶ', () => {
      const source = 'greet a; greet ¦';
      const index = 0;

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        activeParameter: index,
        signatures: [{ activeParameter: index, parameters: expect.any(Array) }],
      });
    });

    test('改行後の別位置へ署名を持ち越さない', () => {
      const source = 'greet a\n¦';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });

    test('セミコロン後の別コマンドへ署名を持ち越さない', () => {
      const source = 'greet a; print ¦';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });

    test('パイプ後の別コマンドへ署名を持ち越さない', () => {
      const source = 'greet a | print ¦';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });

    test('コメント内で署名を返さない', () => {
      const source = '# greet ¦';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });

    test('通常の文字列内で署名を返さない', () => {
      const source = 'print "greet ¦"';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });

    test('リダイレクト先で署名を返さない', () => {
      const source = 'greet a > ¦';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });

    test('行末コメント内で署名を返さない', () => {
      const source = 'greet a # ¦';

      const request = createLanguageFeatureRequest(source);

      const signature = zSignatureHelp(request);

      expect(signature).toBeNull();
    });
  });
});
