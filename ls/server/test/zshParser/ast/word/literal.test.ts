import { describe, expect, test } from 'vitest';
import { findAll } from '../../../../src/zshParser/ast';
import { Lexer } from '../../../../src/zshParser/lexer';
import { Parser } from '../../../../src/zshParser/parser';
import { literalWord } from '../../../../src/zshParser/ast/word/literal';
import { literalWord as compatibilityLiteralWord } from '../../../../src/refreshFunctions/word';

function word(source: string) {
  const lexed = Lexer.tokenize(source, { sourceFile: 'literal.zsh' });
  const parsed = Parser.parse(lexed.tokens, { sourceFile: 'literal.zsh', path: 'literal.zsh' });

  expect(lexed.diagnostics).toEqual([]);
  expect(parsed.diagnostics).toEqual([]);
  const argument = findAll(parsed.ast, 'simpleCommand')[0]?.arguments[0];
  if (!argument) throw new Error('Expected a parsed argument');
  return argument;
}

describe('literalWord', () => {
  test('引用のない静的な値をASTから復元する', () => {
    expect(literalWord(word('print plain'))).toBe('plain');
  });

  test('単一引用符で囲んだ値をASTから復元する', () => {
    expect(literalWord(word("print 'two words'"))).toBe('two words');
  });

  test('二重引用符で囲んだ値をASTから復元する', () => {
    expect(literalWord(word('print "two words"'))).toBe('two words');
  });

  test('引用部分を含む単語をASTから復元する', () => {
    expect(literalWord(word("print pre'fix'"))).toBe('prefix');
  });

  test('エスケープした空白をASTから復元する', () => {
    expect(literalWord(word('print one\\ two'))).toBe('one two');
  });

  test('ドル単一引用符の改行をASTから復元する', () => {
    expect(literalWord(word("print $'one\\ntwo'"))).toBe('one\ntwo');
  });

  test('引用した空文字列をASTから復元する', () => {
    expect(literalWord(word("print ''"))).toBe('');
  });

  test('パラメーター展開を含むWordを静的な値と扱わない', () => {
    expect(literalWord(word('print "$value"'))).toBeNull();
  });

  test('コマンド置換を含むWordを静的な値と扱わない', () => {
    expect(literalWord(word('print "$(print one)"'))).toBeNull();
  });

  test('算術展開を含むWordを静的な値と扱わない', () => {
    expect(literalWord(word('print $(( 1 + 2 ))'))).toBeNull();
  });

  test('指定した位置までの単語を復元する', () => {
    const argument = word("print 'option'=value");

    expect(literalWord(argument, argument.raw.indexOf('='))).toBe('option');
  });

  test('関数索引のimportをASTのliteralWordへ結び付ける', () => {
    expect(compatibilityLiteralWord).toBe(literalWord);
  });
});
