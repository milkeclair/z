import { describe, expect, test } from 'vitest';
import { parseLiteralChoice } from '../../../src/zshHydrator/documentation/literalChoice';

describe('parseLiteralChoice', () => {
  describe('引用された許可値がある場合', () => {
    test('指定位置から一つの値を読み、次の位置を返す', () => {
      const result = parseLiteralChoice("xx'value' tail", 2);

      expect(result).toEqual({ value: 'value', end: 9 });
    });

    test('空の文字列を保持する', () => {
      const result = parseLiteralChoice("''", 0);

      expect(result).toEqual({ value: '', end: 2 });
    });

    test('許可値に含まれるパイプを保持する', () => {
      const result = parseLiteralChoice("'a|b'", 0);

      expect(result).toEqual({ value: 'a|b', end: 5 });
    });
  });

  describe('引用符やバックスラッシュをエスケープする場合', () => {
    test('引用符のエスケープを一段取り除く', () => {
      const result = parseLiteralChoice(String.raw`'it\'s'`, 0);

      expect(result).toEqual({ value: "it's", end: 7 });
    });

    test('バックスラッシュのエスケープを一段取り除く', () => {
      const result = parseLiteralChoice(String.raw`"a\\b"`, 0);

      expect(result).toEqual({ value: String.raw`a\b`, end: 6 });
    });

    test('引用符以外へのバックスラッシュを保持する', () => {
      const result = parseLiteralChoice(String.raw`'a\q'`, 0);

      expect(result).toEqual({ value: String.raw`a\q`, end: 5 });
    });
  });

  describe('引用された許可値が成立しない場合', () => {
    test('引用符で始まらない入力を拒否する', () => {
      expect(parseLiteralChoice('value', 0)).toBeNull();
    });

    test('閉じていない引用符を拒否する', () => {
      expect(parseLiteralChoice("'unfinished", 0)).toBeNull();
    });
  });
});
