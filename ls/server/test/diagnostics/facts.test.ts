import { describe, expect, test } from 'vitest';
import { collectFileFacts } from '../../src/diagnostics/facts';
import { createZshFileHydration } from '../../src/zshHydrator';

describe('collectFileFacts', () => {
  describe('引数の使用状況を調べる場合', () => {
    test('位置パラメータの直接使用を数える', () => {
      const body = 'print "$1"';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('波括弧付きの位置パラメータ使用を数える', () => {
      const body = 'print "$' + '{1}"';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('ローカル変数へ渡した位置パラメータ使用を数える', () => {
      const body = 'local value="$1"; print "$value"';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('単引用内の位置パラメータを使用に数えない', () => {
      const body = "print '$1'";

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toMatchObject([
        {
          range: { start: { line: 0, character: 2 }, end: { line: 0, character: 4 } },
        },
      ]);
    });

    test('コメント内の位置パラメータを使用に数えない', () => {
      const body = '# $1\n:';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toMatchObject([
        {
          range: { start: { line: 0, character: 2 }, end: { line: 0, character: 4 } },
        },
      ]);
    });

    test('入れ子の関数の位置パラメータを外側へ数えない', () => {
      const body = 'nested() { print "$1" }';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toMatchObject([
        {
          range: { start: { line: 0, character: 2 }, end: { line: 0, character: 4 } },
        },
      ]);
    });

    test('全位置引数を転送する場合は未使用の判定を保留する', () => {
      const body = 'print "$@"';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\n# $2: other\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('全位置引数を結合する場合は未使用の判定を保留する', () => {
      const body = 'print "$*"';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\n# $2: other\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('条件式内の位置パラメータは判定を保留する', () => {
      const body = '[[ "$1" = x ]]';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\n# $2: other\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('複雑なパラメータ展開は判定を保留する', () => {
      const body = 'print "$' + '{1:-default}"';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\n# $2: other\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('展開するヒアドキュメント内の参照は判定を保留する', () => {
      const body = 'print <<END\n$1\nEND\n';

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $1: value\n# $2: other\ngreet() { ' + body + ' }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
    });

    test('名前付き引数は実際の参照と取得コマンドで使用を判断する', () => {
      for (const body of [
        'print "$option"',
        'z.arg.named option "$@"',
        'print "$args[option]"',
        'print "$' + '{args[option]}"',
      ]) {
        const file = createZshFileHydration({
          sourceFile: 'arguments.zsh',
          file: 'arguments.zsh',
          content: '# $option: value\ngreet() { ' + body + ' }\n',
        });
        const facts = collectFileFacts(file);

        expect(facts.base.filter((item) => item.code === 'unused-argument')).toEqual([]);
      }

      const file = createZshFileHydration({
        sourceFile: 'arguments.zsh',
        file: 'arguments.zsh',
        content: '# $option: value\ngreet() { print option }\n',
      });
      const facts = collectFileFacts(file);

      expect(facts.base.filter((item) => item.code === 'unused-argument')).toHaveLength(1);
    });
  });
});
