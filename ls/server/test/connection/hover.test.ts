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

describe('zHover', () => {
  describe('定義と呼び出し位置を解決する場合', () => {
    test('通常の関数呼び出しの定義と説明を返す', () => {
      const source = 'gr¦eet x';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Greeting') },
      });
      const definition = zDefinition(request);

      expect(definition).toEqual({
        uri: request.definitionUri,
        range: {
          start: { line: 6, character: 11 },
          end: { line: 6, character: 16 },
        },
      });
    });

    test('引用された関数呼び出しの定義と説明を返す', () => {
      const source = '"gr¦eet" x';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Greeting') },
      });
      const definition = zDefinition(request);

      expect(definition).toEqual({
        uri: request.definitionUri,
        range: {
          start: { line: 6, character: 11 },
          end: { line: 6, character: 16 },
        },
      });
    });

    test('エスケープされた関数呼び出しの定義と説明を返す', () => {
      const source = 'gr\\¦eet x';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Greeting') },
      });
      const definition = zDefinition(request);

      expect(definition).toEqual({
        uri: request.definitionUri,
        range: {
          start: { line: 6, character: 11 },
          end: { line: 6, character: 16 },
        },
      });
    });

    test('置換内の関数呼び出しの定義と説明を返す', () => {
      const source = 'print "$(gr¦eet x)"';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Greeting') },
      });
      const definition = zDefinition(request);

      expect(definition).toEqual({
        uri: request.definitionUri,
        range: {
          start: { line: 6, character: 11 },
          end: { line: 6, character: 16 },
        },
      });
    });

    test('execで呼び出す関数の定義と説明を返す', () => {
      const source = 'exec gr¦eet x';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Greeting') },
      });
      const definition = zDefinition(request);

      expect(definition).toEqual({
        uri: request.definitionUri,
        range: {
          start: { line: 6, character: 11 },
          end: { line: 6, character: 16 },
        },
      });
    });

    test('引数の同名テキストから定義へ移動しない', () => {
      const source = 'print gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('文字列の同名テキストから定義へ移動しない', () => {
      const source = 'print "gr¦eet"';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('コメントの同名テキストから定義へ移動しない', () => {
      const source = '# gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('リダイレクト先の同名テキストから定義へ移動しない', () => {
      const source = 'print > gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('条件式の同名テキストから定義へ移動しない', () => {
      const source = '[[ gr¦eet ]]';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('算術式の同名テキストから定義へ移動しない', () => {
      const source = '(( gr¦eet ))';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('代入値の同名テキストから定義へ移動しない', () => {
      const source = 'value=gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('変数の同名テキストから定義へ移動しない', () => {
      const source = '$gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('command指定の同名テキストから定義へ移動しない', () => {
      const source = 'command gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('builtin指定の同名テキストから定義へ移動しない', () => {
      const source = 'builtin gr¦eet';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('ヒアドキュメント内の同名テキストから定義へ移動しない', () => {
      const source = 'print <<END\ngr¦eet\nEND';

      const request = createLanguageFeatureRequest(source);

      const definition = zDefinition(request);

      expect(definition).toBeNull();
      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('複数名の定義から選択した名前そのものへ移動する', () => {
      const request = createLanguageFeatureRequest('# Multi\nfunction first sec¦ond { : }\n', '');

      const definition = zDefinition(request);

      expect(definition).toMatchObject({
        range: {
          start: { line: 1, character: 15 },
          end: { line: 1, character: 21 },
        },
      });
    });

    test('同一ファイルの直前の再定義を優先する', () => {
      const request = createLanguageFeatureRequest('# Local\ngreet() { : }\ngr¦eet\n');

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('Local') },
      });
      const definition = zDefinition(request);

      expect(definition?.uri).toBe(request.document.uri);
      const item = zCompletion(request)?.[0];

      if (!item) {
        throw new Error('local completion required');
      }

      expect(zCompletionResolve(item, request.snapshot).documentation).toMatchObject({
        value: expect.stringContaining('Local'),
      });
    });
  });

  describe('引数の説明を表示する場合', () => {
    test('restのアスタリスクを表示し、引数がなければsignatureを返さない', () => {
      const request = createLanguageFeatureRequest(
        'helper x ¦',
        '# $*: all arguments\nhelper() { : }\n',
      );

      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({ signatures: [{ label: 'helper $*' }] });
      const request2 = createLanguageFeatureRequest('helper ¦', 'helper() { : }');

      const signature2 = zSignatureHelp(request2);

      expect(signature2).toBeNull();
    });

    test('呼び出し引数の説明を返す', () => {
      const request = createLanguageFeatureRequest('greet "hello ¦world"');

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('first') },
      });
    });

    test('二重引用された名前付き引数の説明を返す', () => {
      const source = 'greet "two=val¦ue"';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('option two') },
      });
    });

    test('動的な値を持つ名前付き引数の説明を返す', () => {
      const source = 'greet "two=$val¦ue"';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('option two') },
      });
    });

    test('単引用された名前付き引数の説明を返す', () => {
      const source = "greet 'two=val¦ue'";

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('option two') },
      });
    });

    test('前の名前付き引数を数えず説明を選ぶ', () => {
      const source = 'greet "one=value" "two=val¦ue"';

      const request = createLanguageFeatureRequest(source);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('option two') },
      });
    });

    test('直接の位置パラメータへ説明を返す', () => {
      const body = 'print "$¦1"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('local first') },
      });
    });

    test('ローカル変数の別名へ説明を返す', () => {
      const body = 'local value="$1"; print "$val¦ue"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('local first') },
      });
    });

    test('波括弧から初期化した別名へ説明を返す', () => {
      const body = 'local value=${1}; print "$val¦ue"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('local first') },
      });
    });

    test('別名の波括弧参照へ説明を返す', () => {
      const body = 'local value=$1; print "${val¦ue}"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('local first') },
      });
    });

    test('再代入された別名へ引数説明を引き継がない', () => {
      const body = 'local value=$1; value=literal; print "$val¦ue"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('別の分岐の代入を別名として扱わない', () => {
      const body = 'if true; then local value=$1; fi; print "$val¦ue"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('入れ子の関数の代入を別名として扱わない', () => {
      const body = 'nested() { local value=$1 }; print "$val¦ue"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('パラメータに接尾辞がある代入を別名として扱わない', () => {
      const body = 'local value=$1suffix; print "$val¦ue"';

      const request = createLanguageFeatureRequest('# $1: local first\nowner() { ' + body + ' }\n');

      const hover = zHover(request);

      expect(hover).toBeNull();
    });

    test('named hashとz.arg.namedの直後のREPLY aliasを扱う', () => {
      for (const body of [
        'local value=$args[option]; print "$val¦ue"',
        'z.arg.named option "$@" && local value=$REPLY; print "$val¦ue"',
      ]) {
        const request = createLanguageFeatureRequest(
          '# $option: option docs\nowner() { ' + body + ' }\n',
        );

        const hover = zHover(request);

        expect(hover).toMatchObject({
          contents: { value: expect.stringContaining('option docs') },
        });
      }
    });
  });

  describe('型アノテーションを表示する場合', () => {
    const codeDefinition =
      "# $behavior? [code | 'call_original']: commands to execute\nrun_code() { : }\n";

    test('関数hoverと補完説明へ型と許可値を残す', () => {
      const request = createLanguageFeatureRequest('run_c¦ode', codeDefinition);

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining("$behavior? [code | 'call_original']:") },
      });
      const item = zCompletion(request)?.[0];

      if (!item) {
        throw new Error('completion required');
      }

      expect(zCompletionResolve(item, request.snapshot).documentation).toMatchObject({
        value: expect.stringContaining("$behavior? [code | 'call_original']:"),
      });
    });

    test('引数hoverと署名にも同じ型と許可値を表示する', () => {
      const request = createLanguageFeatureRequest(
        'run_code behavior=call_ori¦ginal',
        codeDefinition,
      );

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining("[code | 'call_original']") },
      });
      const signature = zSignatureHelp(request);

      expect(signature).toMatchObject({
        signatures: [
          {
            label: "run_code [behavior= [code | 'call_original']]",
            parameters: [{ label: "behavior= [code | 'call_original']" }],
          },
        ],
      });
    });

    test('位置引数と可変長引数のcode型も表示する', () => {
      const request = createLanguageFeatureRequest(
        'run_c¦ode',
        "# $1 [code]: command\n# $@ [code | 'noop']: remaining commands\nrun_code() { : }\n",
      );

      const hover = zHover(request);

      expect(hover).toMatchObject({
        contents: { value: expect.stringContaining('$1 [code]:') },
      });
      const hover2 = zHover(request);

      expect(hover2).toMatchObject({
        contents: { value: expect.stringContaining("$@ [code | 'noop']:") },
      });
    });
  });
});
