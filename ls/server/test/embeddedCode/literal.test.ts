import { describe, expect, test } from 'vitest';
import { decodeLiteral, literalValue } from '../../src/embeddedCode/literal';
import { codeRange, createCodeSourceMap } from '../../src/embeddedCode/sourceMap';
import { createZshFileHydration } from '../../src/zshHydrator';
import { findAll } from '../../src/zshParser/ast';

function word(argument: string, prefix = 'run ') {
  const content = prefix + argument + '\n';
  const file = createZshFileHydration({ sourceFile: 'literal.zsh', file: 'literal.zsh', content });

  return { content, word: findAll(file.ast, 'simpleCommand')[0].arguments[0] };
}

describe('decodeLiteral', () => {
  describe('静的な引用を取り除く場合', () => {
    test('単引用を取り除き中の二重引用を保持する', () => {
      const raw = '\'print "$1"\'';
      const text = 'print "$1"';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('二重引用のエスケープを取り除く', () => {
      const raw = String.raw`"print \"\$1\""`;
      const text = 'print "$1"';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('連結された引用部分を一つの値にする', () => {
      const raw = '\'pri\'"nt x"';
      const text = 'print x';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('ANSI引用の改行を復号する', () => {
      const raw = String.raw`$'print x\nmissing'`;
      const text = 'print x\nmissing';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('ANSI引用の日本語Unicodeを復号する', () => {
      const raw = String.raw`$'\x70rint \u65e5\u672c'`;
      const text = 'print 日本';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('ANSI引用の日本語UTF-8バイトを復号する', () => {
      const raw = String.raw`$'\xe6\x97\xa5\xe6\x9c\xac'`;
      const text = '日本';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('引用外の行継続を取り除く', () => {
      const raw = 'pri\\\nnt';
      const text = 'print';

      const result = decodeLiteral(word(raw).word);

      expect(result?.text).toBe(text);
      expect(result?.spans).toHaveLength(text.length);
    });

    test('数字のないANSI escapeがNULになる場合は解析を保留する', () => {
      expect(decodeLiteral(word(String.raw`$'\x'`).word)).toBeNull();
      expect(decodeLiteral(word(String.raw`$'\u'`).word)).toBeNull();
    });

    test('サロゲートを含むコード文字列の解析を保留する', () => {
      const raw = String.raw`$'\uD800'`;

      expect(decodeLiteral(word(raw).word)).toBeNull();
    });

    test('Unicode上限を越えるコード文字列の解析を保留する', () => {
      const raw = String.raw`$'\Uffffffff'`;

      expect(decodeLiteral(word(raw).word)).toBeNull();
    });

    test('変数だけからなる文字列の解析を保留する', () => {
      const raw = '"$code"';

      expect(decodeLiteral(word(raw).word)).toBeNull();
    });

    test('コマンド置換を含む文字列の解析を保留する', () => {
      const raw = '"print $(run)"';

      expect(decodeLiteral(word(raw).word)).toBeNull();
    });

    test('算術展開を含む文字列の解析を保留する', () => {
      const raw = '"print $((1+2))"';

      expect(decodeLiteral(word(raw).word)).toBeNull();
    });

    test('名前付きprefixを除去しても元のspanを保持する', () => {
      const input = word("code='missing'");
      const decoded = decodeLiteral(input.word);

      expect(decoded).not.toBeNull();

      if (!decoded) {
        return;
      }

      const source = literalValue(decoded, 5);
      const range = codeRange(createCodeSourceMap(input.word, source), {
        start: { offset: 0, line: 0, character: 0 },
        end: { offset: 7, line: 0, character: 7 },
      });

      expect(input.content.slice(range.start.offset, range.end.offset)).toBe('missing');
      expect(range.start.character).toBe(10);
    });

    test('ANSI escapeと複数行を元の文字列位置へ戻す', () => {
      const input = word(String.raw`$'print ok\n\x6dissing'`, '  run ');
      const decoded = decodeLiteral(input.word);

      if (!decoded) {
        throw new Error('static literal expected');
      }

      const start = decoded.text.indexOf('missing');
      const range = codeRange(createCodeSourceMap(input.word, decoded), {
        start: { offset: start, line: 1, character: 0 },
        end: { offset: start + 7, line: 1, character: 7 },
      });

      expect(input.content.slice(range.start.offset, range.end.offset)).toBe(
        String.raw`\x6dissing`,
      );
      expect(range.start.line).toBe(0);
    });
  });
});
