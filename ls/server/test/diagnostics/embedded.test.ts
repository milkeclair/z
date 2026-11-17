import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterEach, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { validateTextDocument } from '../../src/diagnostics/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import type { Diagnostics } from '../../src/diagnostics/type';
import { analyzeEmbeddedCode } from '../../src/embeddedCode';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { Lexer } from '../../src/zshParser/lexer';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
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

function createDiagnosticProject(content: string, documentation = definitions) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-code-diagnostic-'));
  temporaryDirectories.track(root);
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
    textDocument: document,
    snapshot,
    diagnostics,
  };
}

const calls = (items: readonly Diagnostics[]) =>
  items.filter((item) =>
    ['undefined-command', 'missing-positional-argument', 'missing-named-argument'].includes(
      item.code ?? '',
    ),
  );

describe('analyzeEmbeddedCode', () => {
  describe('型アノテーションのあるコード引数を診断する場合', () => {
    test('一般名の関数のコード引数を診断し、元の文字列へrangeを返す', () => {
      const source = "run_code code='missing-command'\n";
      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([
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
      const project = createDiagnosticProject("run_code code='needs'\n");

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
      const project2 = createDiagnosticProject("run_code code='needs value'\n");

      const diagnostics2 = validateTextDocument(project2);

      expect(calls(diagnostics2)).toEqual([]);
    });

    test('通常の文字列と型アノテーションのない引数は診断しない', () => {
      const project = createDiagnosticProject("print 'missing-command'\n");

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toEqual([]);
      const project2 = createDiagnosticProject(
        "run_code code='missing-command'\n",
        '# $code: text\nrun_code() { print "$code" }\n',
      );

      const diagnostics2 = validateTextDocument(project2);

      expect(calls(diagnostics2)).toEqual([]);
    });

    test('許可された特殊値はコードへ変換しない', () => {
      const definition =
        '# $code [code | \'call_original\']: commands\nrun_code() { print "$code" }\n';

      const project = createDiagnosticProject('run_code code=call_original\n', definition);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toEqual([]);
      const project2 = createDiagnosticProject("run_code code='missing-command'\n", definition);

      const diagnostics2 = validateTextDocument(project2);

      expect(calls(diagnostics2)).toHaveLength(1);
    });

    test('外側の変数で内容が変わる文字列は保留する', () => {
      const project = createDiagnosticProject('run_code code="$commands"\n');

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toEqual([]);
      const project2 = createDiagnosticProject('run_code code="missing-command $value"\n');

      const diagnostics2 = validateTextDocument(project2);

      expect(calls(diagnostics2)).toEqual([]);
    });

    test('引数の型アノテーションの変更で未編集の呼び出しを再評価する', () => {
      const project = createDiagnosticProject(
        "run_code code='missing-command'\n",
        '# $code: text\nrun_code() { print "$code" }\n',
      );
      fs.writeFileSync(project.definitionFile, definitions);
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      expect(calls(next.files.get(project.textDocument.uri)?.items ?? [])).toHaveLength(1);
    });

    test('単引用された名前付きコード引数を診断する', () => {
      const source = "run_code 'code=missing-command'\n";

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('二重引用された名前付きコード引数を診断する', () => {
      const source = 'run_code "code=missing-command"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('名前の途中に引用があるコード引数を診断する', () => {
      const source = "run_code co'de'='missing-command'\n";

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([{ code: 'undefined-command' }]);
    });

    test('位置引数とrest引数のコード型を扱う', () => {
      const positional = '# $1 [code]: commands\nrun_code() { print "$1" }\n';

      const project = createDiagnosticProject("run_code 'missing-command'\n", positional);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toHaveLength(1);
      const rest = '# $@ [code]: commands\nrun_code() { print "$@" }\n';

      const project2 = createDiagnosticProject("run_code 'missing-one' 'missing-two'\n", rest);

      const diagnostics2 = validateTextDocument(project2);

      expect(calls(diagnostics2)).toHaveLength(2);
    });

    test('ANSI escapeのコマンド位置を元のescape範囲へ戻す', () => {
      const source = String.raw`run_code code=$'print ok\n\x6dissing-command'` + '\n';
      const item = calls(validateTextDocument(createDiagnosticProject(source)))[0];

      expect(item?.code).toBe('undefined-command');
      expect(item?.range).toEqual({
        start: { line: 0, character: source.indexOf(String.raw`\x6dissing`) },
        end: { line: 0, character: source.indexOf(String.raw`\x6dissing`) + 18 },
      });
    });

    test('CRLFと日本語を含む物理行の位置を保持する', () => {
      const source = "run_code code='print 日本\r\n  missing-command'\r\n";

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([
        {
          range: { start: { line: 1, character: 2 }, end: { line: 1, character: 17 } },
        },
      ]);
    });

    test('入れ子のコード文字列も元のfileへ診断を返す', () => {
      const source = 'run_code code="run_code code=\'missing-command\'"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([
        {
          code: 'undefined-command',
          range: { start: { line: 0, character: source.indexOf('missing-command') } },
        },
      ]);
    });

    test('内側の関数・alias・zmodload宣言をそのコード内だけで解決する', () => {
      const source =
        "run_code code='inner() { : }; alias local_alias=print; zmodload zsh/zselect; inner; local_alias; zselect'\ninner\n";

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([
        { code: 'undefined-command', range: { start: { line: 1, character: 0 } } },
      ]);
    });

    test('内側の構文エラーを元の文字列内へ返す', () => {
      const source = "run_code code='if true; then print ok'\n";
      const items = validateTextDocument(createDiagnosticProject(source)).filter(
        (item) => item.source === 'z-ls/parser',
      );

      expect(items.length).toBeGreaterThan(0);
      expect(
        items.every(
          (item) =>
            item.range.start.line === 0 && item.range.start.character >= source.indexOf('if'),
        ),
      ).toBe(true);
    });

    test('内側のignoreを仮想行へ適用し、外側へ漏らさない', () => {
      const source =
        String.raw`run_code code=$'missing-one # zls: ignore\nmissing-two'` + '\nmissing-three\n';
      const items = calls(validateTextDocument(createDiagnosticProject(source)));

      expect(items.map((item) => item.message.split(' ')[0])).toEqual([
        'missing-two',
        'missing-three',
      ]);
    });

    test('外側の制御コメントで同じ物理行のコード診断を抑制する', () => {
      const project = createDiagnosticProject(
        "run_code code='missing-command' # zls: ignore undefined-command\n",
      );

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toEqual([]);
    });

    test('外側のコマンド置換は重複診断しない', () => {
      const source = 'run_code code="$(missing-command)"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toHaveLength(1);
    });

    test('許可値の編集で未編集のコードを再診断する', () => {
      const project = createDiagnosticProject(
        "run_code code='call_original'\n",
        '# $code [code | \'call_original\']: commands\nrun_code() { print "$code" }\n',
      );

      const diagnostics2 = validateTextDocument(project);

      expect(calls(diagnostics2)).toEqual([]);
      fs.writeFileSync(project.definitionFile, definitions);
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      expect(calls(next.files.get(project.textDocument.uri)?.items ?? [])).toHaveLength(1);
    });

    test('未編集のreportとfactsを再利用する', () => {
      const project = createDiagnosticProject("run_code code='missing-command'\n");

      expect(
        refreshDiagnosticSnapshot({
          snapshot: project.snapshot,
          environment,
          previous: project.diagnostics,
        }),
      ).toBe(project.diagnostics);
    });

    test('重複した許可値を変更しても正しく再評価する', () => {
      const project = createDiagnosticProject(
        "run_code code='new_value'\n",
        "# $code [code | 'old' | 'old']: commands\nrun_code() { print \"$code\" }\n",
      );

      const diagnostics2 = validateTextDocument(project);

      expect(calls(diagnostics2)).toHaveLength(1);
      fs.writeFileSync(
        project.definitionFile,
        "# $code [code | 'old' | 'new_value']: commands\nrun_code() { print \"$code\" }\n",
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({
        snapshot,
        environment,
        previous: project.diagnostics,
      });

      expect(calls(next.files.get(project.textDocument.uri)?.items ?? [])).toEqual([]);
    });

    test('外部文書のreceiverと内側の関数スコープを解決する', () => {
      const project = createDiagnosticProject('');
      const text = definitions + "run_code code='missing-command'\n";
      const document = TextDocument.create(
        pathToFileURL(path.join(path.dirname(project.root), 'outside-code.zsh')).href,
        'shellscript',
        1,
        text,
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [project.textDocument, document],
        previous: project.snapshot,
      });
      const next = refreshDiagnosticSnapshot({ snapshot, environment });

      expect(calls(next.files.get(document.uri)?.items ?? [])).toMatchObject([
        { code: 'undefined-command' },
      ]);
    });

    test('内側の関数が引数契約を持つ場合も診断する', () => {
      const source = 'run_code code=\'# $1: value\ninner() { print "$1" }; inner\'\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
    });

    test('展開で位置が不明でも名前付きコードは見つける', () => {
      const project = createDiagnosticProject("run_code $@ code='missing-command'\n");

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)).toHaveLength(1);
      const positional = '# $2 [code]: commands\nrun_code() { print "$2" }\n';

      const project2 = createDiagnosticProject("run_code $@ 'missing-command'\n", positional);

      const diagnostics2 = validateTextDocument(project2);

      expect(calls(diagnostics2)).toEqual([]);
    });

    test('絵文字より後の位置をUTF-16として返す', () => {
      const source = "print 😀; run_code code='missing-command'\n";

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(calls(diagnostics)[0]?.range.start.character).toBe(source.indexOf('missing-command'));
    });

    test('command modifierでは関数のコード引数として扱わない', () => {
      const items = calls(
        validateTextDocument(createDiagnosticProject("command run_code code='missing-command'\n")),
      );

      expect(items).toHaveLength(1);
      expect(items[0].message.startsWith('run_code ')).toBe(true);
    });

    test('変更がなければコードを再parseしない', () => {
      const project = createDiagnosticProject("run_code code='missing-command'\n");
      const spy = vi.spyOn(Lexer, 'tokenize');

      expect(
        refreshDiagnosticSnapshot({
          snapshot: project.snapshot,
          environment,
          previous: project.diagnostics,
        }),
      ).toBe(project.diagnostics);
      expect(spy).not.toHaveBeenCalled();
    });

    test('入れ子の深さ上限で解析を止める', () => {
      const limits = { maxDepth: 0 };

      const project = createDiagnosticProject("run_code code='missing-command'\n");
      const report = project.diagnostics.files.get(project.textDocument.uri);

      if (!report) {
        throw new Error('caller report expected');
      }

      const spy = vi.spyOn(Lexer, 'tokenize');
      const items = analyzeEmbeddedCode(
        project.snapshot,
        report.file,
        report.facts.calls,
        project.diagnostics.context,
        limits,
      ).diagnostics;

      expect(items).toMatchObject([{ code: 'embedded-analysis-limit' }]);
      expect(spy).not.toHaveBeenCalled();
    });

    test('解析文字数の上限で解析を止める', () => {
      const limits = { maxText: 4 };

      const project = createDiagnosticProject("run_code code='missing-command'\n");
      const report = project.diagnostics.files.get(project.textDocument.uri);

      if (!report) {
        throw new Error('caller report expected');
      }

      const spy = vi.spyOn(Lexer, 'tokenize');
      const items = analyzeEmbeddedCode(
        project.snapshot,
        report.file,
        report.facts.calls,
        project.diagnostics.context,
        limits,
      ).diagnostics;

      expect(items).toMatchObject([{ code: 'embedded-analysis-limit' }]);
      expect(spy).not.toHaveBeenCalled();
    });

    test('コード内のドキュメント診断も元の位置へ返す', () => {
      const source = "run_code code='# $1 [unknown]: value\ninner() { : }'\n";

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(diagnostics).toMatchObject([
        { code: 'invalidParameterDoc', source: 'z-ls/documentation' },
      ]);
    });

    test('コマンド文字列を実行しない', () => {
      const project = createDiagnosticProject('');
      const marker = path.join(project.root, 'never-created');
      const document = TextDocument.create(
        project.textDocument.uri,
        'shellscript',
        2,
        "run_code code='print changed > " + marker + "'\n",
      );
      const snapshot = refreshFunctionSnapshot({
        projectRoot: project.root,
        documents: [document],
        previous: project.snapshot,
      });
      refreshDiagnosticSnapshot({ snapshot, environment, previous: project.diagnostics });

      expect(fs.existsSync(marker)).toBe(false);
    });

    test('一つの呼び出しの複数コード引数でも合計予算を守る', () => {
      const project = createDiagnosticProject(
        "run_code 'missing-one' 'missing-two'\n",
        '# $@ [code]: commands\nrun_code() { print "$@" }\n',
      );
      const report = project.diagnostics.files.get(project.textDocument.uri);

      if (!report) {
        throw new Error('caller report expected');
      }

      const items = analyzeEmbeddedCode(
        project.snapshot,
        report.file,
        report.facts.calls,
        project.diagnostics.context,
        { maxText: 20 },
      ).diagnostics;

      expect(items.filter((item) => item.code === 'embedded-analysis-limit')).toHaveLength(1);
      expect(items.filter((item) => item.code === 'undefined-command')).toHaveLength(1);
    });
  });
});
