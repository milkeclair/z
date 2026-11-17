import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { afterAll, afterEach, beforeAll, describe, expect, test, vi } from 'vitest';
import { TextDocument } from 'vscode-languageserver-textdocument';
import type { ShellEnvironment } from '../../src/diagnostics/environment';
import { emptyShellEnvironment, readShellEnvironment } from '../../src/diagnostics/environment';
import { validateTextDocument } from '../../src/diagnostics/main';
import { refreshDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { refreshFunctionSnapshot } from '../../src/refreshFunctions/main';
import { createIOState } from '../../src/util/ioState';
import { createTemporaryDirectories } from '../support/tempDirectories';

const temporaryDirectories = createTemporaryDirectories();

const environmentRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'z-diag-shell-'));

const environmentReference = createIOState<ShellEnvironment>(emptyShellEnvironment());

beforeAll(async () => {
  fs.writeFileSync(
    path.join(environmentRoot, '.zshrc'),
    [
      "alias fixture-shell-alias='print value'",
      "alias -g FIXTURE_GLOBAL='one two'",
      'alias -s fixture_suffix=cat',
      'fixture-shell-function() { : }',
      'autoload -Uz fixture-shell-autoload',
    ].join('\n'),
  );
  environmentReference.replace(
    await readShellEnvironment({ env: { ...process.env, ZDOTDIR: environmentRoot } }),
  );

  expect(environmentReference.read().kind).toBe('available');
});

afterAll(() => fs.rmSync(environmentRoot, { recursive: true, force: true }));

afterEach(() => {
  vi.restoreAllMocks();
  temporaryDirectories.cleanup();
});

const definition = '# $1: first\n# $2: second\ngreet() { print "$1" "$2" }\n';

function createDiagnosticProject(
  content: string,
  definitions = definition,
  shell = environmentReference.read(),
) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'z-diag-'));
  temporaryDirectories.track(root);
  const definitionUri = pathToFileURL(path.join(root, 'definition.zsh')).href;
  fs.writeFileSync(path.join(root, 'definition.zsh'), definitions);
  const document = TextDocument.create(
    pathToFileURL(path.join(root, 'caller.zsh')).href,
    'shellscript',
    1,
    content,
  );
  const snapshot = refreshFunctionSnapshot({ projectRoot: root, documents: [document] });
  const diagnostics = refreshDiagnosticSnapshot({ snapshot, environment: shell });

  return {
    root,
    snapshot,
    diagnostics,
    textDocument: document,
    definitionUri,
  };
}

const semantic = (items: ReturnType<typeof validateTextDocument>) =>
  items.filter((item) =>
    ['missing-positional-argument', 'missing-named-argument', 'undefined-command'].includes(
      item.code ?? '',
    ),
  );

describe('validateTextDocument', () => {
  describe('呼び出しの引数を診断する場合', () => {
    test('一般名の関数・正確なコマンドrangeと位置番号で不足を判定する', () => {
      const project = createDiagnosticProject('  "greet" one\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        {
          code: 'missing-positional-argument',
          message: 'Missing required argument(s): $2',
          range: { start: { line: 0, character: 2 }, end: { line: 0, character: 9 } },
        },
      ]);
      const project2 = createDiagnosticProject(
        'greet one two\n',
        '# $3: third\ngreet() { print "$3" }\n',
      );

      const diagnostics2 = validateTextDocument(project2);

      expect(semantic(diagnostics2)).toMatchObject([
        { message: 'Missing required argument(s): $3' },
      ]);
    });

    test('通常の引数にある関数名を呼び出しにしない', () => {
      const source = 'print greet\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('文字列中の関数名を呼び出しにしない', () => {
      const source = 'print "greet"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('コメント中の関数名を呼び出しにしない', () => {
      const source = '# greet\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('リダイレクト先の関数名を呼び出しにしない', () => {
      const source = 'print > greet\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('複数行の引用を一つの引数として数える', () => {
      const source = 'greet "one\ntwo" three\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('コマンド置換の中の呼び出しを診断する', () => {
      const source = 'print "$(greet one two)"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('行継続でつながる引数を同じ呼び出しで数える', () => {
      const source = 'greet one ' + String.fromCharCode(92) + '\n two\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('パイプの後のコマンドを引数に数えない', () => {
      const source = 'greet one | print two\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
    });

    test('リダイレクト先を引数に数えない', () => {
      const source = 'greet one > two\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
    });

    test('セミコロンの後のコマンドを引数に数えない', () => {
      const source = 'greet one; print two\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
    });

    test('論理積の後のコマンドを引数に数えない', () => {
      const source = 'greet one && print two\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([{ code: 'missing-positional-argument' }]);
    });

    test('引用されていない変数の展開数を保留する', () => {
      const source = 'greet $values\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('全位置引数の展開数を保留する', () => {
      const source = 'greet "$@"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('globの展開数を保留する', () => {
      const source = 'greet *\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('グローバルaliasの展開数を保留する', () => {
      const source = 'greet FIXTURE_GLOBAL\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('配列の展開数を保留する', () => {
      const source = 'greet "$' + '{array[@]}"\n';

      const project = createDiagnosticProject(source);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('引用したscalar展開は一つの引数として扱う', () => {
      const project = createDiagnosticProject('greet "$value"\n');

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        { message: 'Missing required argument(s): $2' },
      ]);
    });

    test('名前付き引数を静的なkeyから照合する', () => {
      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet option=""\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
      const project2 = createDiagnosticProject('greet option=\n', doc);

      const diagnostics2 = validateTextDocument(project2);

      expect(semantic(diagnostics2)).toEqual([]);
      const project3 = createDiagnosticProject('greet "option=value"\n', doc);

      const diagnostics3 = validateTextDocument(project3);

      expect(semantic(diagnostics3)).toEqual([]);
    });

    test('二重引用された名前付き引数を数える', () => {
      const argument = '"option=value with spaces"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('二重引用された空の名前付き引数を数える', () => {
      const argument = '"option="';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('二重引用された動的な値も同じ名前へ対応付ける', () => {
      const argument = '"option=$value"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('単引用された名前付き引数を数える', () => {
      const argument = "'option=value with spaces'";

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('名前の途中に引用があっても照合する', () => {
      const argument = 'op"tion"=value';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('名前と値が別々に引用されても照合する', () => {
      const argument = '"option"="$value"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('値だけが引用された名前付き引数を数える', () => {
      const argument = 'option="value"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('名前のエスケープを除いて照合する', () => {
      const argument = 'op\\tion=value';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });

    test('別名の名前付き引数では不足を解消しない', () => {
      const argument = '"other=value"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        { code: 'missing-named-argument', message: 'Missing required named argument: option' },
      ]);
    });

    test('数字から始まる名前を名前付き引数にしない', () => {
      const argument = '"9option=value"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        { code: 'missing-named-argument', message: 'Missing required named argument: option' },
      ]);
    });

    test('ハイフンを含む別名では不足を解消しない', () => {
      const argument = '"option-extra=value"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        { code: 'missing-named-argument', message: 'Missing required named argument: option' },
      ]);
    });

    test('等号のない単語では不足を解消しない', () => {
      const argument = '"option"';

      const doc = '# $option: value\ngreet() { print "$option" }\n';

      const project = createDiagnosticProject('greet ' + argument + '\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        { code: 'missing-named-argument', message: 'Missing required named argument: option' },
      ]);
    });

    test('引用した名前付き引数を位置引数へ数えない', () => {
      const doc = '# $1: first\n# $option: value\ngreet() { print "$1" "$option" }\n';

      const project = createDiagnosticProject('greet "option=value"\n', doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toMatchObject([
        { code: 'missing-positional-argument', message: 'Missing required argument(s): $1' },
      ]);
      const project2 = createDiagnosticProject('greet "option=$value" first\n', doc);

      const diagnostics2 = validateTextDocument(project2);

      expect(semantic(diagnostics2)).toEqual([]);
    });

    test('失敗ログの実例を名前付き引数として認識する', () => {
      const doc = '# $message: error message\nz.t._log.failure.handle() { print "$message" }\n';
      const source =
        'z.t._log.failure.handle "message=failed: expected [ $expect_display ] but got [ $actual_display ]"\n';

      const project = createDiagnosticProject(source, doc);

      const diagnostics = validateTextDocument(project);

      expect(semantic(diagnostics)).toEqual([]);
    });
  });
});
