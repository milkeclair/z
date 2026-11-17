import { describe, expect, test, vi } from 'vitest';
import { directivesOf, documentationOf, hydrateAst } from '../../src/zshHydrator/hydrate';
import * as Ast from '../../src/zshParser/ast';
import { Lexer } from '../../src/zshParser/lexer';
import { Parser } from '../../src/zshParser/parser';

describe('hydrateAst', () => {
  describe('付加する情報がない場合', () => {
    test('AST全体の変換を省き、元の参照を返す', () => {
      const source = 'print ok # 通常のコメント\n';
      const { ast } = Parser.parse(Lexer.tokenize(source).tokens);
      const mapAst = vi.spyOn(Ast, 'mapAst');

      try {
        const hydrated = hydrateAst(ast, source);

        expect(hydrated).toBe(ast);
        expect(mapAst).not.toHaveBeenCalled();
      } finally {
        mapAst.mockRestore();
      }
    });
  });

  describe('関数ドキュメントがなく制御コメントだけがある場合', () => {
    test('指定した名前空間の制御コメントを付加する', () => {
      const source = 'print ok # custom: ignore rule\n';
      const { ast } = Parser.parse(Lexer.tokenize(source).tokens);

      const hydrated = hydrateAst(ast, source, { directiveNamespaces: ['custom'] });

      expect(directivesOf(hydrated.comments[0])).toMatchObject([
        { namespace: 'custom', command: 'ignore', arguments: [{ value: 'rule' }] },
      ]);
      expect(directivesOf(ast.comments[0])).toEqual([]);
    });

    test('名前空間の設定変更で古い制御情報を取り除く', () => {
      const source = 'print ok # zls: ignore rule\n';
      const { ast } = Parser.parse(Lexer.tokenize(source).tokens);
      const hydrated = hydrateAst(ast, source);

      const updated = hydrateAst(hydrated, source, { directiveNamespaces: ['custom'] });

      expect(directivesOf(updated.comments[0])).toEqual([]);
      expect(directivesOf(hydrated.comments[0])).toHaveLength(1);
    });
  });

  describe('関数ドキュメントと他の構文が混在する場合', () => {
    test('置換の中の関数へ文書を付加し、制御コメントの参照を共有する', () => {
      const source = [
        'print before',
        'source $(',
        '  # inner function',
        '  # zls: ignore rule',
        '  inner() { : }',
        ')',
        'print after # zls: ignore after',
        '',
      ].join('\n');
      const { ast } = Parser.parse(Lexer.tokenize(source).tokens);

      const hydrated = hydrateAst(ast, source);
      const definition = Ast.findAll(hydrated, 'functionDefinition')[0];
      const sourceCommand = Ast.findAll(hydrated, 'simpleCommand').find(
        (command) => command.semantic.role === 'source',
      );

      expect(documentationOf(definition)?.description).toMatchObject([{ text: 'inner function' }]);
      expect(definition.leadingDoc?.comments[1]).toBe(hydrated.comments[1]);
      expect(directivesOf(hydrated.comments[1])).toMatchObject([
        { command: 'ignore', arguments: [{ value: 'rule' }] },
      ]);
      expect(directivesOf(hydrated.comments[2])).toMatchObject([
        { command: 'ignore', arguments: [{ value: 'after' }] },
      ]);
      if (sourceCommand?.semantic.role !== 'source') {
        throw new Error('sourceコマンドが必要です');
      }

      expect(sourceCommand.semantic.source.target).toBe(sourceCommand.arguments[0]);
      expect(hydrated.body.items[0]).toBe(ast.body.items[0]);
      expect(hydrated.body.items[2]).toBe(ast.body.items[2]);
    });

    test('閉じ括弧のない関数本体でも文書を付加する', () => {
      const source = 'if true; then\n  # inner function\n  inner() {\n';
      const { ast, diagnostics } = Parser.parse(Lexer.tokenize(source).tokens);

      const hydrated = hydrateAst(ast, source);
      const definition = Ast.findAll(hydrated, 'functionDefinition')[0];

      expect(diagnostics.length).toBeGreaterThan(0);
      expect(documentationOf(definition)?.description).toMatchObject([{ text: 'inner function' }]);
      expect(definition.leadingDoc?.comments[0]).toBe(hydrated.comments[0]);
    });
  });
});
