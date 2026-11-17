import { describe, expect, test } from 'vitest';
import { createDiagnosticSnapshot } from '../../src/diagnostics/snapshot';
import { codeArguments } from '../../src/embeddedCode/arguments';
import { createZshFileHydration } from '../../src/zshHydrator';
import { findAll } from '../../src/zshParser/ast';

function createArgumentInput(documentation: string, call: string) {
  const file = createZshFileHydration({
    sourceFile: 'arguments.zsh',
    file: 'arguments.zsh',
    content: documentation + '\nrun_code() { : }\n' + call + '\n',
  });
  const target = file.functions[0]?.definition;
  const command = findAll(file.ast, 'simpleCommand').find(
    (node) => node.commandName?.word.raw === 'run_code',
  );

  if (!target || !command) {
    throw new Error('コード引数の定義と呼び出しが必要です');
  }

  return { target, command };
}

describe('codeArguments', () => {
  describe('名前付き引数と位置引数を対応付ける場合', () => {
    test('名前付きコード引数から接頭辞を除いたコードを返す', () => {
      const { target, command } = createArgumentInput(
        '# $code [code]: commands',
        "run_code code='print ok'",
      );
      const context = createDiagnosticSnapshot().context;

      const result = codeArguments(command, target, context);

      expect(result.arguments).toMatchObject([
        { kind: 'code', source: { text: 'print ok' }, prefix: 'code=' },
      ]);
    });

    test('名前付き引数を数えず二番目の位置引数を選ぶ', () => {
      const { target, command } = createArgumentInput(
        '# $1: label\n# $2 [code]: commands\n# $mode?: mode',
        "run_code mode=fast label 'print ok'",
      );
      const context = createDiagnosticSnapshot().context;

      const result = codeArguments(command, target, context);

      expect(result.arguments).toMatchObject([
        { kind: 'code', source: { text: 'print ok' }, prefix: '' },
      ]);
    });

    test('位置引数の個数が不明でも後続の名前付き引数を選ぶ', () => {
      const { target, command } = createArgumentInput(
        '# $1 [code]: positional commands\n# $code [code]: named commands',
        "run_code $values 'not-static' code='print ok'",
      );
      const context = createDiagnosticSnapshot().context;

      const result = codeArguments(command, target, context);

      expect(result.arguments).toMatchObject([
        { kind: 'code', source: { text: 'print ok' }, prefix: 'code=' },
      ]);
    });
  });

  describe('許可値や未完成の文字列を扱う場合', () => {
    test('許可値に一致する文字列をコードとして返さない', () => {
      const { target, command } = createArgumentInput(
        "# $code [code | 'noop']: commands",
        "run_code code='noop'",
      );
      const context = createDiagnosticSnapshot().context;

      const result = codeArguments(command, target, context);

      expect(result.arguments).toEqual([]);
    });

    test('編集用の指定があれば閉じていない引用も返す', () => {
      const { target, command } = createArgumentInput('# $1 [code]: commands', "run_code 'print");
      const context = createDiagnosticSnapshot().context;

      const complete = codeArguments(command, target, context);
      const editing = codeArguments(command, target, context, 1024, true);

      expect(complete.arguments).toEqual([]);
      expect(editing.arguments).toMatchObject([
        { kind: 'code', source: { text: 'print\n', unterminated: true } },
      ]);
    });
  });

  describe('複数のコード引数で予算を共有する場合', () => {
    test('一番目で使った文字数を二番目の残り予算へ反映する', () => {
      const { target, command } = createArgumentInput(
        '# $@ [code]: commands',
        "run_code 'print first' 'print second'",
      );
      const context = createDiagnosticSnapshot().context;

      const result = codeArguments(command, target, context, 15);

      expect(result.arguments).toMatchObject([
        { kind: 'code', source: { text: 'print first' } },
        { kind: 'limit' },
      ]);
      expect(result.inspected).toBe(13);
    });
  });
});
