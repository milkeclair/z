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

describe('static code literal decoding', () => {
  test.each([
    ['\'print "$1"\'', 'print "$1"'],
    [String.raw`"print \"\$1\""`, 'print "$1"'],
    ['\'pri\'"nt x"', 'print x'],
    [String.raw`$'print x\nmissing'`, 'print x\nmissing'],
    [String.raw`$'\x70rint \u65e5\u672c'`, 'print 日本'],
    [String.raw`$'\xe6\x97\xa5\xe6\x9c\xac'`, '日本'],
    ['pri\\\nnt', 'print'],
  ])('静的な引用だけを除去する: %s', (raw, text) => {
    const result = decodeLiteral(word(raw).word);
    expect(result?.text).toBe(text);
    expect(result?.spans).toHaveLength(text.length);
  });

  test('数字のないANSI escapeがNULになる場合は解析を保留する', () => {
    expect(decodeLiteral(word(String.raw`$'\x'`).word)).toBeNull();
    expect(decodeLiteral(word(String.raw`$'\u'`).word)).toBeNull();
  });

  test.each([String.raw`$'\uD800'`, String.raw`$'\Uffffffff'`])(
    '値が成立しないUnicode escapeを保留する: %s',
    (raw) => {
      expect(decodeLiteral(word(raw).word)).toBeNull();
    },
  );

  test.each(['"$code"', '"print $(run)"', '"print $((1+2))"'])(
    '外側で展開される値は確定しない: %s',
    (raw) => {
      expect(decodeLiteral(word(raw).word)).toBeNull();
    },
  );

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
    expect(input.content.slice(range.start.offset, range.end.offset)).toBe(String.raw`\x6dissing`);
    expect(range.start.line).toBe(0);
  });
});
