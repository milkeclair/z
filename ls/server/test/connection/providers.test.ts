import { afterEach, describe, expect, test, vi } from 'vitest';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { TextDocument } from 'vscode-languageserver-textdocument';
import { Lexer } from '../../src/zshParser/lexer';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { zCompletion } from '../../src/connection/completion';
import { zCompletionResolve } from '../../src/connection/completionResolve';
import { zHover } from '../../src/connection/hover';
import { zDefinition } from '../../src/connection/definition';
import { zSignatureHelp } from '../../src/connection/signatureHelp';

const roots: string[] = [];
const definition = [
  '# Greeting', '# $1: first', '# $2?: second', '# $@: tail',
  '# $one: option one', '# $two?: option two', '  function greet { : }', '',
].join('\n');
function fixture(source: string, definitions = definition) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-provider-'));
  roots.push(root);
  const definitionUri = pathToFileURL(path.join(root, '日本語 name.zsh')).href;
  fs.writeFileSync(path.join(root, '日本語 name.zsh'), definitions);
  const offset = source.indexOf('¦');
  if (offset < 0) throw new Error('cursor required');
  const document = TextDocument.create(pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript', 1, source.replace('¦', ''));
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const documents = { get: (uri: string) => uri === document.uri ? document : undefined };
  const params = { textDocument: { uri: document.uri }, position: document.positionAt(offset) };
  return {
    snapshot, document, definitionUri, params,
    complete: () => zCompletion({ params, documents, snapshot, showPrivateFunctions: true }),
    hover: () => zHover({ params, documents, snapshot }),
    definition: () => zDefinition({ params, documents, snapshot }),
    signature: () => zSignatureHelp({ params, documents, snapshot }),
  };
}
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) fs.rmSync(root, { recursive: true, force: true });
});

describe('completion@AST', () => {
  test.each(['gr¦eet', '"gr¦eet"', "'gr¦eet'"])('command word全体を置換する: %s', source => {
    const result = fixture(source).complete();
    expect(result).toHaveLength(1);
    expect(result?.[0]).toMatchObject({ label: 'greet', textEdit: {
      range: { start: { line: 0, character: 0 }, end: { line: 0, character: source.length - 1 } },
      newText: 'greet',
    } });
  });
  test.each(['¦', '  ¦', '\n  ¦', 'print x; ¦', 'print x | ¦', 'true && ¦',
    '{ ¦', '( ¦', 'if ¦', 'if true; then ¦', 'while ¦', 'for x in y; do ¦', 'print "$(¦)"', 'print "$(  ¦)"'])('空のcommand位置: %s', source => {
    expect(fixture(source).complete()?.map(item => item.label)).toContain('greet');
  });
  test.each(['print gr¦', 'print "gr¦"', '# gr¦', 'print > gr¦', 'value=gr¦',
    'for x in gr¦; do :; done', 'case x in gr¦) :;; esac', '[[ gr¦ ]]',
    '(( gr¦ ))', 'for x in y\n ¦do :; done', 'case x in\n ¦x) :;; esac', 'builtin gr¦', 'command gr¦', 'exec gr¦',
    'print <<END\ngr¦\nEND', '$gr¦', 'print "x$(print gr¦)"'])('command以外を候補にしない: %s', source => {
    expect(fixture(source).complete()).toEqual([]);
  });
  test('複数行のcommand wordには不正なcompletion editを返さない', () => {
    expect(fixture('gr' + String.fromCharCode(92) + '\\ne¦et').complete()).toEqual([]);
  });
  test('substitution内部のcommandを探索する', () => {
    expect(fixture('print "$(gr¦)"').complete()?.[0].label).toBe('greet');
  });
  test('静的な引用名を索引化し、挿入時に引用する', () => {
    const f = fixture('¦', "function 'hello world' 'if' { : }\n");
    expect(f.complete()?.map(item => [item.label, item.textEdit])).toMatchObject([
      ['hello world', { newText: "'hello world'" }], ['if', { newText: "'if'" }],
    ]);
  });
  test('glob・引用符・modifier名はリテラルとして挿入する', () => {
    const quoted = "'a'" + String.fromCharCode(92) + "''b'";
    const f = fixture('¦', "function 'hello?' command " + quoted + " { : }");
    expect(f.complete()?.map(item => [item.label, item.textEdit?.newText])).toEqual([
      ['hello?', "'hello?'"], ['command', "'command'"], ["a'b", quoted],
    ]);
  });
  test('resolveは現在のsnapshotの文書情報を使い、入力itemを変更しない', () => {
    const f = fixture('gr¦');
    const item = f.complete()?.[0];
    if (!item) throw new Error('completion required');
    const resolved = zCompletionResolve(item, f.snapshot);
    expect(item.documentation).toBeUndefined();
    expect(resolved.documentation).toMatchObject({ value: expect.stringContaining('Greeting') });
    expect(zCompletionResolve({ label: 'greet', data: { uri: 1 } }, f.snapshot)).toEqual({ label: 'greet', data: { uri: 1 } });
  });
});

describe('hover and definition@AST', () => {
  test.each(['gr¦eet x', '"gr¦eet" x', "gr\\¦eet x", 'print "$(gr¦eet x)"'])('実際の呼び出しだけを解決する: %s', source => {
    const f = fixture(source);
    expect(f.hover()).toMatchObject({ contents: { value: expect.stringContaining('Greeting') } });
    expect(f.definition()).toEqual({ uri: f.definitionUri, range: {
      start: { line: 6, character: 11 }, end: { line: 6, character: 16 },
    } });
  });
  test.each(['print gr¦eet', 'print "gr¦eet"', '# gr¦eet', 'print > gr¦eet',
    '[[ gr¦eet ]]', '(( gr¦eet ))', 'value=gr¦eet', '$gr¦eet',
    'command gr¦eet', 'builtin gr¦eet', 'exec gr¦eet',
    'print <<END\ngr¦eet\nEND'])('同名テキストへ定義ジャンプしない: %s', source => {
    const f = fixture(source);
    expect(f.definition()).toBeNull();
    expect(f.hover()).toBeNull();
  });
  test('複数名の定義から選択した名前そのものへ移動する', () => {
    const f = fixture('# Multi\nfunction first sec¦ond { : }\n', '');
    expect(f.definition()).toMatchObject({ range: {
      start: { line: 1, character: 15 }, end: { line: 1, character: 21 },
    } });
  });
  test('同一ファイルの直前の再定義を優先する', () => {
    const f = fixture('# Local\ngreet() { : }\ngr¦eet\n');
    expect(f.hover()).toMatchObject({ contents: { value: expect.stringContaining('Local') } });
    expect(f.definition()?.uri).toBe(f.document.uri);
    const item = f.complete()?.[0];
    if (!item) throw new Error('local completion required');
    expect(zCompletionResolve(item, f.snapshot).documentation).toMatchObject({
      value: expect.stringContaining('Local'),
    });
  });
});

describe('signature help@AST', () => {
  test.each([
    ['greet ¦', 0], ['greet "hello world" ¦', 1],
    ['greet "hello\nworld" ¦', 1], ['greet a ' + String.fromCharCode(92) + '\n ¦', 1],
    ['greet one=value ¦', 0], ['greet two=val¦ue', 3],
    ['greet "hello\nworld" ¦', 1], ['greet a ' + String.fromCharCode(92) + '\n ¦', 1],
    ['print "$(greet a ¦)"', 1], ['print x | greet ¦', 0],
    ['greet a; greet ¦', 0],
  ])('%s -> %s', (source, index) => {
    expect(fixture(source).signature()).toMatchObject({ activeParameter: index,
      signatures: [{ activeParameter: index, parameters: expect.any(Array) }] });
  });
  test.each(['greet a\n¦', 'greet a; print ¦', 'greet a | print ¦',
    '# greet ¦', 'print "greet ¦"', 'greet a > ¦', 'greet a # ¦'])('呼び出し境界を越えない: %s', source => {
    expect(fixture(source).signature()).toBeNull();
  });
});

describe('provider snapshot reuse', () => {
  test('要求処理は文書を再解析せず、同じsnapshotを参照する', () => {
    const f = fixture('gr¦eet');
    const spy = vi.spyOn(Lexer, 'tokenize');
    for (let request = 0; request < 10; request += 1) {
      const item = f.complete()?.[0];
      expect(f.definition()?.uri).toBe(f.definitionUri);
      expect(f.hover()).not.toBeNull();
      f.signature();
      if (item) zCompletionResolve(item, f.snapshot);
    }
    expect(spy).not.toHaveBeenCalled();
  });
  test('未反映のversionには古いASTを返さない', () => {
    const f = fixture('gr¦eet');
    TextDocument.update(f.document, [{ text: 'other' }], 2);
    expect(f.hover()).toBeNull();
    expect(f.definition()).toBeNull();
    expect(f.complete()).toEqual([]);
  });
});

describe('argument hover@AST', () => {
  test('restのアスタリスクを表示し、引数がなければsignatureを返さない', () => {
    const f = fixture('helper x ¦', '# $*: all arguments\nhelper() { : }\n');
    expect(f.signature()).toMatchObject({ signatures: [{ label: 'helper $*' }] });
    expect(fixture('helper ¦', 'helper() { : }').signature()).toBeNull();
  });
  test('呼び出し引数の説明を返す', () => {
    expect(fixture('greet "hello ¦world"').hover()).toMatchObject({
      contents: { value: expect.stringContaining('first') },
    });
  });
  test.each(['print "$¦1"', 'local value="$1"; print "$val¦ue"',
    'local value=${1}; print "$val¦ue"', 'local value=$1; print "${val¦ue}"'])('位置引数・そのalias: %s', body => {
    const f = fixture('# $1: local first\nowner() { ' + body + ' }\n');
    expect(f.hover()).toMatchObject({ contents: { value: expect.stringContaining('local first') } });
  });
  test.each(['local value=$1; value=literal; print "$val¦ue"',
    'if true; then local value=$1; fi; print "$val¦ue"',
    'nested() { local value=$1 }; print "$val¦ue"',
    'local value=$1suffix; print "$val¦ue"'])('無関係な代入をaliasにしない: %s', body => {
    expect(fixture('# $1: local first\nowner() { ' + body + ' }\n').hover()).toBeNull();
  });
  test('named hashとz.arg.namedの直後のREPLY aliasを扱う', () => {
    for (const body of ['local value=$args[option]; print "$val¦ue"',
      'z.arg.named option "$@" && local value=$REPLY; print "$val¦ue"']) {
      expect(fixture('# $option: option docs\nowner() { ' + body + ' }\n').hover())
        .toMatchObject({ contents: { value: expect.stringContaining('option docs') } });
    }
  });
});
