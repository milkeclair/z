import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { analyzeEmbeddedCode } from '../../src/embeddedCode';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { Lexer } from '../../src/zshParser/lexer';

const roots: string[] = [];
afterEach(() => {
  vi.restoreAllMocks();
  for (const root of roots.splice(0)) {
    fs.rmSync(root, { recursive: true, force: true });
  }
});
const environment: ShellEnvironment = {
  kind: 'available',
  commands: new Set(['cat']),
  builtins: new Set(['print', ':', 'true', 'eval', 'alias', 'zmodload']),
  aliases: new Set(),
  globalAliases: new Set(),
  suffixAliases: new Set(),
  functions: new Set(),
  commandBuiltins: false,
};
const definitions = [
  '# $code [code]: commands',
  'run_code() { print "$code" }',
  '# $1: value',
  'needs() { print "$1" }',
  '',
].join('\n');
function fixture(content: string, documentation = definitions) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-code-diagnostic-'));
  roots.push(root);
  const definitionFile = path.join(root, 'definition.zsh');
  fs.writeFileSync(definitionFile, documentation);
  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    content,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment });
  return {
    root,
    definitionFile,
    document,
    snapshot,
    diagnostics,
    items: diagnostics.files.get(document.uri)?.items ?? [],
  };
}
const calls = (items: ReturnType<typeof fixture>['items']) =>
  items.filter((item) =>
    ['undefined-command', 'missing-positional-argument', 'missing-named-argument'].includes(
      item.code ?? '',
    ),
  );

describe('documented code argument diagnostics', () => {
  test('一般名の関数のコード引数を診断し、元の文字列へrangeを返す', () => {
    const source = "run_code code='missing-command'\n";
    const f = fixture(source);
    expect(calls(f.items)).toMatchObject([
      {
        code: 'undefined-command',
        range: {
          start: { line: 0, character: source.indexOf('missing-command') },
          end: { line: 0, character: source.indexOf('missing-command') + 15 },
        },
      },
    ]);
  });

  test('文字列内の既知関数の必須引数も検証する', () => {
    expect(calls(fixture("run_code code='needs'\n").items)).toMatchObject([
      { code: 'missing-positional-argument' },
    ]);
    expect(calls(fixture("run_code code='needs value'\n").items)).toEqual([]);
  });

  test('通常の文字列と未注釈の引数は診断しない', () => {
    expect(calls(fixture("print 'missing-command'\n").items)).toEqual([]);
    expect(
      calls(
        fixture(
          "run_code code='missing-command'\n",
          '# $code: text\nrun_code() { print "$code" }\n',
        ).items,
      ),
    ).toEqual([]);
  });

  test('許可された特殊値はコードへ変換しない', () => {
    const definition =
      '# $code [code | \'call_original\']: commands\nrun_code() { print "$code" }\n';
    expect(calls(fixture('run_code code=call_original\n', definition).items)).toEqual([]);
    expect(calls(fixture("run_code code='missing-command'\n", definition).items)).toHaveLength(1);
  });

  test('外側の変数で内容が変わる文字列は保留する', () => {
    expect(calls(fixture('run_code code="$commands"\n').items)).toEqual([]);
    expect(calls(fixture('run_code code="missing-command $value"\n').items)).toEqual([]);
  });

  test('引数注釈の変更で未編集の呼び出しを再評価する', () => {
    const f = fixture(
      "run_code code='missing-command'\n",
      '# $code: text\nrun_code() { print "$code" }\n',
    );
    fs.writeFileSync(f.definitionFile, definitions);
    const snapshot = refreshFunctionSnapshot({
      projectRoot: f.root,
      documents: [f.document],
      previous: f.snapshot,
    });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(calls(next.files.get(f.document.uri)?.items ?? [])).toHaveLength(1);
  });
  test.each([
    "run_code 'code=missing-command'\n",
    'run_code "code=missing-command"\n',
    "run_code co'de'='missing-command'\n",
  ])('名前付きの引用形式を診断する: %s', (source) => {
    expect(calls(fixture(source).items)).toMatchObject([{ code: 'undefined-command' }]);
  });

  test('位置引数とrest引数のコード型を扱う', () => {
    const positional = '# $1 [code]: commands\nrun_code() { print "$1" }\n';
    expect(calls(fixture("run_code 'missing-command'\n", positional).items)).toHaveLength(1);
    const rest = '# $@ [code]: commands\nrun_code() { print "$@" }\n';
    expect(calls(fixture("run_code 'missing-one' 'missing-two'\n", rest).items)).toHaveLength(2);
  });

  test('ANSI escapeのコマンド位置を元のescape範囲へ戻す', () => {
    const source = String.raw`run_code code=$'print ok\n\x6dissing-command'` + '\n';
    const item = calls(fixture(source).items)[0];
    expect(item?.code).toBe('undefined-command');
    expect(item?.range).toEqual({
      start: { line: 0, character: source.indexOf(String.raw`\x6dissing`) },
      end: { line: 0, character: source.indexOf(String.raw`\x6dissing`) + 18 },
    });
  });

  test('CRLFと日本語を含む物理行の位置を保持する', () => {
    const source = "run_code code='print 日本\r\n  missing-command'\r\n";
    expect(calls(fixture(source).items)).toMatchObject([
      {
        range: { start: { line: 1, character: 2 }, end: { line: 1, character: 17 } },
      },
    ]);
  });

  test('入れ子のコード文字列も元のfileへ診断を返す', () => {
    const source = 'run_code code="run_code code=\'missing-command\'"\n';
    expect(calls(fixture(source).items)).toMatchObject([
      {
        code: 'undefined-command',
        range: { start: { line: 0, character: source.indexOf('missing-command') } },
      },
    ]);
  });

  test('内側の関数・alias・zmodload宣言をそのコード内だけで解決する', () => {
    const source =
      "run_code code='inner() { : }; alias local_alias=print; zmodload zsh/zselect; inner; local_alias; zselect'\ninner\n";
    expect(calls(fixture(source).items)).toMatchObject([
      { code: 'undefined-command', range: { start: { line: 1, character: 0 } } },
    ]);
  });

  test('内側の構文エラーを元の文字列内へ返す', () => {
    const source = "run_code code='if true; then print ok'\n";
    const items = fixture(source).items.filter((item) => item.source === 'z-ls/parser');
    expect(items.length).toBeGreaterThan(0);
    expect(
      items.every(
        (item) => item.range.start.line === 0 && item.range.start.character >= source.indexOf('if'),
      ),
    ).toBe(true);
  });

  test('内側のignoreを仮想行へ適用し、外側へ漏らさない', () => {
    const source =
      String.raw`run_code code=$'missing-one # zls: ignore\nmissing-two'` + '\nmissing-three\n';
    const items = calls(fixture(source).items);
    expect(items.map((item) => item.message.split(' ')[0])).toEqual([
      'missing-two',
      'missing-three',
    ]);
  });

  test('外側の制御コメントで同じ物理行のコード診断を抑制する', () => {
    expect(
      calls(fixture("run_code code='missing-command' # zls: ignore undefined-command\n").items),
    ).toEqual([]);
  });

  test('外側のコマンド置換は重複診断しない', () => {
    const source = 'run_code code="$(missing-command)"\n';
    expect(calls(fixture(source).items)).toHaveLength(1);
  });

  test('許可値の編集で未編集のコードを再診断する', () => {
    const f = fixture(
      "run_code code='call_original'\n",
      '# $code [code | \'call_original\']: commands\nrun_code() { print "$code" }\n',
    );
    expect(calls(f.items)).toEqual([]);
    fs.writeFileSync(f.definitionFile, definitions);
    const snapshot = refreshFunctionSnapshot({
      projectRoot: f.root,
      documents: [f.document],
      previous: f.snapshot,
    });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(calls(next.files.get(f.document.uri)?.items ?? [])).toHaveLength(1);
  });

  test('未編集のreportとfactsを再利用する', () => {
    const f = fixture("run_code code='missing-command'\n");
    expect(
      refreshDiagnosticSnapshot({ snapshot: f.snapshot, environment, previous: f.diagnostics }),
    ).toBe(f.diagnostics);
  });

  test('重複した許可値を変更しても正しく再評価する', () => {
    const f = fixture(
      "run_code code='new_value'\n",
      "# $code [code | 'old' | 'old']: commands\nrun_code() { print \"$code\" }\n",
    );
    expect(calls(f.items)).toHaveLength(1);
    fs.writeFileSync(
      f.definitionFile,
      "# $code [code | 'old' | 'new_value']: commands\nrun_code() { print \"$code\" }\n",
    );
    const snapshot = refreshFunctionSnapshot({
      projectRoot: f.root,
      documents: [f.document],
      previous: f.snapshot,
    });
    const next = refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(calls(next.files.get(f.document.uri)?.items ?? [])).toEqual([]);
  });

  test('外部文書のreceiverと内側の関数スコープを解決する', () => {
    const f = fixture('');
    const text = definitions + "run_code code='missing-command'\n";
    const document = TextDocument.create(
      pathToFileURL(path.join(path.dirname(f.root), 'outside-code.zsh')).href,
      'shellscript',
      1,
      text,
    );
    const snapshot = refreshFunctionSnapshot({
      projectRoot: f.root,
      documents: [f.document, document],
      previous: f.snapshot,
    });
    const next = refreshDiagnosticSnapshot({ snapshot, environment });
    expect(calls(next.files.get(document.uri)?.items ?? [])).toMatchObject([
      { code: 'undefined-command' },
    ]);
  });

  test('内側の関数が引数契約を持つ場合も診断する', () => {
    const source = 'run_code code=\'# $1: value\ninner() { print "$1" }; inner\'\n';
    expect(calls(fixture(source).items)).toMatchObject([{ code: 'missing-positional-argument' }]);
  });

  test('展開で位置が不明でも名前付きコードは見つける', () => {
    expect(calls(fixture("run_code $@ code='missing-command'\n").items)).toHaveLength(1);
    const positional = '# $2 [code]: commands\nrun_code() { print "$2" }\n';
    expect(calls(fixture("run_code $@ 'missing-command'\n", positional).items)).toEqual([]);
  });

  test('絵文字より後の位置をUTF-16として返す', () => {
    const source = "print 😀; run_code code='missing-command'\n";
    expect(calls(fixture(source).items)[0]?.range.start.character).toBe(
      source.indexOf('missing-command'),
    );
  });

  test('command modifierでは関数のコード引数として扱わない', () => {
    const items = calls(fixture("command run_code code='missing-command'\n").items);
    expect(items).toHaveLength(1);
    expect(items[0].message.startsWith('run_code ')).toBe(true);
  });

  test('変更がなければコードを再parseしない', () => {
    const f = fixture("run_code code='missing-command'\n");
    const spy = vi.spyOn(Lexer, 'tokenize');
    expect(
      refreshDiagnosticSnapshot({ snapshot: f.snapshot, environment, previous: f.diagnostics }),
    ).toBe(f.diagnostics);
    expect(spy).not.toHaveBeenCalled();
  });

  test.each([{ maxDepth: 0 }, { maxText: 4 }])('処理上限で深い再parseを止める: %j', (limits) => {
    const f = fixture("run_code code='missing-command'\n");
    const report = f.diagnostics.files.get(f.document.uri);
    if (!report) {
      throw new Error('caller report expected');
    }
    const spy = vi.spyOn(Lexer, 'tokenize');
    const items = analyzeEmbeddedCode(
      f.snapshot,
      report.file,
      report.facts.calls,
      f.diagnostics.context,
      limits,
    ).diagnostics;
    expect(items).toMatchObject([{ code: 'embedded-analysis-limit' }]);
    expect(spy).not.toHaveBeenCalled();
  });

  test('コード内のドキュメント診断も元の位置へ返す', () => {
    const source = "run_code code='# $1 [unknown]: value\ninner() { : }'\n";
    expect(fixture(source).items).toMatchObject([
      { code: 'invalidParameterDoc', source: 'z-ls/documentation' },
    ]);
  });

  test('コマンド文字列を実行しない', () => {
    const f = fixture('');
    const marker = path.join(f.root, 'never-created');
    const document = TextDocument.create(
      f.document.uri,
      'shellscript',
      2,
      "run_code code='print changed > " + marker + "'\n",
    );
    const snapshot = refreshFunctionSnapshot({
      projectRoot: f.root,
      documents: [document],
      previous: f.snapshot,
    });
    refreshDiagnosticSnapshot({ snapshot, environment, previous: f.diagnostics });
    expect(fs.existsSync(marker)).toBe(false);
  });

  test('一つの呼び出しの複数コード引数でも合計予算を守る', () => {
    const f = fixture(
      "run_code 'missing-one' 'missing-two'\n",
      '# $@ [code]: commands\nrun_code() { print "$@" }\n',
    );
    const report = f.diagnostics.files.get(f.document.uri);
    if (!report) {
      throw new Error('caller report expected');
    }
    const items = analyzeEmbeddedCode(
      f.snapshot,
      report.file,
      report.facts.calls,
      f.diagnostics.context,
      { maxText: 20 },
    ).diagnostics;
    expect(items.filter((item) => item.code === 'embedded-analysis-limit')).toHaveLength(1);
    expect(items.filter((item) => item.code === 'undefined-command')).toHaveLength(1);
  });
});
