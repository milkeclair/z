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
  test.each([
    ['print plain', 'plain'],
    ["print 'two words'", 'two words'],
    ['print "two words"', 'two words'],
    ["print pre'fix'", 'prefix'],
    ['print one\\ two', 'one two'],
    ["print $'one\\ntwo'", 'one\ntwo'],
    ["print ''", ''],
  ])('静的な値の引用をASTから復元する: %s', (source, value) => {
    expect(literalWord(word(source))).toBe(value);
  });

  test.each(['print "$value"', 'print "$(print one)"', 'print $(( 1 + 2 ))'])(
    '展開を含むWordを静的な値と扱わない: %s', source => {
      expect(literalWord(word(source))).toBeNull();
    });

  test('指定された終端まで復元し、既存のimportとの互換性を保持する', () => {
    const argument = word("print 'option'=value");

    expect(literalWord(argument, argument.raw.indexOf('='))).toBe('option');
    expect(compatibilityLiteralWord).toBe(literalWord);
  });
});
