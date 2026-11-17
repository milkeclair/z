import { describe, expect, test } from 'vitest';
import { parseCodeParameterType } from '../../../src/zshHydrator/documentation/parameterType';

describe('parseCodeParameterType', () => {
  describe('許可値のないcode型の場合', () => {
    test('型と終端位置を返す', () => {
      const result = parseCodeParameterType('[code]', 0);

      expect(result).toEqual({ end: 6, literalValues: [] });
    });
  });

  describe('code型アノテーションを読む場合', () => {
    test('指定位置から閉じ角括弧までを読む', () => {
      expect(parseCodeParameterType("xx[code | 'call_original'] tail", 2)).toEqual({
        end: 26,
        literalValues: ['call_original'],
      });
    });

    test('引用内のpipeとescaped quoteをliteralとして保持する', () => {
      const text = String.raw`[code | 'a|b' | 'it\'s' | "a\\b"]`;

      expect(parseCodeParameterType(text, 0)?.literalValues).toEqual([
        'a|b',
        "it's",
        String.raw`a\b`,
      ]);
    });

    test('未対応の型を拒否する', () => {
      const text = '[unknown]';

      expect(parseCodeParameterType(text, 0)).toBeNull();
    });

    test('パイプ後の許可値不足を拒否する', () => {
      const text = '[code | ]';

      expect(parseCodeParameterType(text, 0)).toBeNull();
    });

    test('閉じていない許可値を拒否する', () => {
      const text = "[code | 'x'";

      expect(parseCodeParameterType(text, 0)).toBeNull();
    });

    test('型の後の余分な文字を拒否する', () => {
      const text = '[code extra]';

      expect(parseCodeParameterType(text, 0)).toBeNull();
    });

    test('引用符のない許可値を拒否する', () => {
      const text = '[code | value]';

      expect(parseCodeParameterType(text, 0)).toBeNull();
    });
  });
});
