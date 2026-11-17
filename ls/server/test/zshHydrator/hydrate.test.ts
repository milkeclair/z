import { describe, expect, test, vi } from 'vitest';
import { directivesOf, hydrateAst } from '../../src/zshHydrator/hydrate';
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
});
