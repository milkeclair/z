import { describe, expect, test } from 'vitest';
import { findAll } from '../../../src/zshParser/ast';
import { Lexer } from '../../../src/zshParser/lexer';
import { Parser } from '../../../src/zshParser/parser';
import { astContractViolations } from './contracts';

describe('Parser.parse', () => {
  describe('括弧付きのglob引数を解析する場合', () => {
    test('括弧付きパターンを一つの引数にする', () => {
      const source = 'print (foo|bar)';
      const expected = ['(foo|bar)'];

      const parsed = Parser.parse(Lexer.tokenize(source).tokens);

      expect(parsed.diagnostics).toEqual([]);
      expect(findAll(parsed.ast, 'simpleCommand')[0].arguments.map((word) => word.raw)).toEqual(
        expected,
      );
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
    });

    test('閉じ括弧に続くコロンも同じ単語へ含める', () => {
      const source = 'print (or any of the parent directories): .git';
      const expected = ['(or any of the parent directories):', '.git'];

      const parsed = Parser.parse(Lexer.tokenize(source).tokens);

      expect(parsed.diagnostics).toEqual([]);
      expect(findAll(parsed.ast, 'simpleCommand')[0].arguments.map((word) => word.raw)).toEqual(
        expected,
      );
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
    });

    test('globの修飾子を一つの引数へ含める', () => {
      const source = 'print *(.)';
      const expected = ['*(.)'];

      const parsed = Parser.parse(Lexer.tokenize(source).tokens);

      expect(parsed.diagnostics).toEqual([]);
      expect(findAll(parsed.ast, 'simpleCommand')[0].arguments.map((word) => word.raw)).toEqual(
        expected,
      );
      expect(astContractViolations(parsed.ast, parsed.tokens, source)).toEqual([]);
    });

    test('コマンド位置の括弧はsubshellとして残す', () => {
      const source = 'print x; (print y)';
      const parsed = Parser.parse(Lexer.tokenize(source).tokens);

      expect(parsed.diagnostics).toEqual([]);
      expect(
        findAll(parsed.ast, 'simpleCommand').map((command) => command.commandName?.value),
      ).toEqual(['print', 'print']);
    });

    test('閉じていない括弧は構文診断を維持する', () => {
      const parsed = Parser.parse(Lexer.tokenize('print (foo').tokens);

      expect(parsed.diagnostics.length).toBeGreaterThan(0);
    });
  });
});
