import { describe, expect, test } from 'vitest';
import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import { findAll } from '../../../src/zshParser/ast';
import { astContractViolations } from './contracts';

describe('parenthesized glob words', () => {
  test.each([
    ['print (foo|bar)', ['(foo|bar)']],
    ['print (or any of the parent directories): .git', ['(or any of the parent directories):', '.git']],
    ['print *(.)', ['*(.)']],
  ])('括弧と後続の文字を引数wordへ保持する: %s', (source, expected) => {
    const parsed = Parser.parse(Lexer.tokenize(source).tokens);
    expect(parsed.diagnostics).toEqual([]);
    expect(findAll(parsed.ast, 'simpleCommand')[0].arguments.map(word => word.raw)).toEqual(expected);
    expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
  });

  test('コマンド位置の括弧はsubshellとして残す', () => {
    const source = 'print x; (print y)';
    const parsed = Parser.parse(Lexer.tokenize(source).tokens);
    expect(parsed.diagnostics).toEqual([]);
    expect(findAll(parsed.ast, 'simpleCommand').map(command => command.commandName?.value)).toEqual(['print', 'print']);
  });

  test('閉じていない括弧は構文診断を維持する', () => {
    const parsed = Parser.parse(Lexer.tokenize('print (foo').tokens);
    expect(parsed.diagnostics.length).toBeGreaterThan(0);
  });
});
