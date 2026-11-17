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

const roots: string[] = [];
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) {
    fs.rmSync(root, { recursive: true, force: true });
  }
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

function createProviderFixture(
  source: string,
  outside = false,
  extraDefinitions: readonly string[] = [],
) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-code-provider-'));
  roots.push(root);
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
    complete: () =>
      zCompletion({ params, documents, snapshot, programs, showPrivateFunctions: true }),
    hover: () => zHover({ params, documents, snapshot, programs }),
    definition: () => zDefinition({ params, documents, snapshot, programs }),
    signature: () => zSignatureHelp({ params, documents, snapshot, programs }),
  };
}

describe('code argument providers', () => {
  test.each([
    "run_code code='gr¦'",
    'run_code code="gr¦"',
    "run_code code=$'gr¦'",
    "run_code code='gr¦",
    'run_code code="gr¦',
    "run_code code=$'gr¦",
    "run_code 'code=gr¦'",
    'run_code code="run_code code=\'gr¦\'"',
    "print 日本😀; run_code code='print value\ngr¦'",
  ])('コード内のコマンドを元文書へ補完する: %s', (source) => {
    const scenario = createProviderFixture(source);
    const item = scenario.complete()?.find((item) => item.label === 'greet');
    expect(item).toMatchObject({ textEdit: { newText: 'greet' } });
    if (!item?.textEdit || !('range' in item.textEdit)) {
      throw new Error('edit expected');
    }
    const start = scenario.document.offsetAt(item.textEdit.range.start);
    const end = scenario.document.offsetAt(item.textEdit.range.end);
    expect(scenario.document.getText().slice(start, end)).toBe('gr');
    expect(
      zCompletionResolve(item, scenario.snapshot, scenario.programs).documentation,
    ).toMatchObject({
      value: expect.stringContaining('Greeting'),
    });
  });

  test.each(["run_code code='¦'", "run_code code='¦"])(
    '空のコード位置から候補を返す: %s',
    (source) => {
      expect(
        createProviderFixture(source)
          .complete()
          ?.map((item) => item.label),
      ).toContain('greet');
    },
  );

  test('コード内のhover・署名・定義を通常の関数へ接続する', () => {
    const scenario = createProviderFixture("run_code code='gr¦eet value'");
    expect(scenario.hover()).toMatchObject({
      contents: { value: expect.stringContaining('Greeting') },
    });
    expect(scenario.definition()?.uri).toBe(scenario.definitionUri);
    expect(createProviderFixture("run_code code='greet ¦'").signature()).toMatchObject({
      signatures: [{ label: 'greet $1' }],
      activeParameter: 0,
    });
  });

  test('内側の定義を補完・解決し、元の文字列位置へ定義ジャンプする', () => {
    const source = "run_code code='inner() { : }; in¦ner'";
    const scenario = createProviderFixture(source);
    expect(scenario.complete()?.map((item) => item.label)).toContain('inner');
    expect(scenario.definition()).toMatchObject({
      uri: scenario.document.uri,
      range: { start: { line: 0, character: source.indexOf('inner') } },
    });
    expect(
      createProviderFixture(source.replace('in¦ner', 'inner') + '\nin¦ner').definition(),
    ).toBeNull();
  });

  test('外側の引用符へ安全に文字列を挿入する', () => {
    for (const source of [
      "run_code code='hello¦'",
      'run_code code="hello¦"',
      "run_code code=$'hello¦'",
      "run_code code='hel'lo¦",
      'run_code code=hello¦',
    ]) {
      const scenario = createProviderFixture(source);
      const item = scenario.complete()?.find((item) => item.label === 'hello world');
      if (!item?.textEdit || !('range' in item.textEdit)) {
        throw new Error('edit expected');
      }
      const edited = TextDocument.applyEdits(scenario.document, [item.textEdit]);
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

  test.each(["print 'gr¦'", "run_code code='no¦op'", 'run_code code="$gr¦"'])(
    '通常の文字列・許可値・外側の動的展開をコードにしない: %s',
    (source) => {
      expect(createProviderFixture(source).complete()).toEqual([]);
    },
  );

  test('編集中の要求で同じ埋め込みASTを再利用する', () => {
    const scenario = createProviderFixture("run_code code='gr¦eet value'");
    const spy = vi.spyOn(Lexer, 'tokenize');
    for (let i = 0; i < 5; i++) {
      scenario.complete();
      scenario.hover();
      scenario.definition();
      scenario.signature();
    }
    expect(spy).not.toHaveBeenCalled();
  });
});

test('workspace外の文書にある定義を、そのコード内だけで解決する', () => {
  const scenario = createProviderFixture(
    "outside_only() { : }; run_code code='out¦side_only'",
    true,
  );
  expect(scenario.snapshot.targets.has('outside_only')).toBe(false);
  const item = scenario.complete()?.find((item) => item.label === 'outside_only');
  expect(item).toBeDefined();
  expect(scenario.definition()?.uri).toBe(scenario.document.uri);
  if (!item) {
    throw new Error('outside completion required');
  }
  expect(
    zCompletionResolve(item, scenario.snapshot, scenario.programs).documentation,
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
    const scenario = createProviderFixture('run_code code="run_code code=\'¦\'"', false, extra);
    const item = scenario.complete()?.find((item) => item.label === name);
    if (!item?.textEdit || !('range' in item.textEdit)) {
      throw new Error('edit expected: ' + name);
    }
    let text = TextDocument.applyEdits(scenario.document, [item.textEdit]);
    for (let level = 0; level < 2; level++) {
      const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: text });
      expect(file.lexerDiagnostics).toEqual([]);
      const argument = findAll(file.ast, 'simpleCommand')[0].arguments[0];
      const decoded = decodeLiteral(argument);
      if (!decoded) {
        throw new Error('outer expansion introduced: ' + name);
      }
      text = literalValue(decoded, 5).text;
    }
    const file = createZshFileHydration({ sourceFile: 'x', file: 'x', content: text });
    const word = findAll(file.ast, 'simpleCommand')[0].commandName?.word;
    if (!word) {
      throw new Error('command expected');
    }
    expect(literalWord(word)).toBe(name);
  }
});

test('物理的に複数行になる補完編集やカーソルを含まない範囲を返さない', () => {
  expect(
    createProviderFixture('run_code code="gr' + String.fromCharCode(92) + '\nee¦t"').complete(),
  ).toEqual([]);
  expect(createProviderFixture("run_code code='gr''¦'").complete()).toEqual([]);
});
