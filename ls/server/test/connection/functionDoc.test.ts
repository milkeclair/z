import { describe, expect, test } from 'vitest';
import { argumentDisplay, argumentType } from '../../src/connection/functionDoc';
import type { FuncArg } from '../../src/getFunctions/type';

describe('argumentType', () => {
  describe('型アノテーションがない場合', () => {
    test('空の文字列を返す', () => {
      const argument: FuncArg = { name: 'behavior', position: -1, optional: true, isNamed: true };

      const annotation = argumentType(argument);

      expect(annotation).toBe('');
    });
  });

  describe('code型を表示する場合', () => {
    test('型名を角括弧で囲む', () => {
      const argument: FuncArg = {
        name: 'behavior',
        position: -1,
        optional: true,
        isNamed: true,
        valueType: 'code',
      };

      const annotation = argumentType(argument);

      expect(annotation).toBe('[code]');
    });

    test('許可値の引用符とバックスラッシュをエスケープする', () => {
      const argument: FuncArg = {
        name: 'behavior',
        position: -1,
        optional: true,
        isNamed: true,
        valueType: 'code',
        literalValues: ['call_original', "a'b", 'a\\b'],
      };

      const annotation = argumentType(argument);

      expect(annotation).toBe("[code | 'call_original' | 'a\\'b' | 'a\\\\b']");
    });
  });
});

describe('argumentDisplay', () => {
  describe('名前付き引数を表示する場合', () => {
    test('型アノテーションがなければ引数名と等号を返す', () => {
      const argument: FuncArg = { name: 'behavior', position: -1, optional: true, isNamed: true };

      const display = argumentDisplay(argument);

      expect(display).toBe('behavior=');
    });

    test('引数名の後へcode型を付ける', () => {
      const argument: FuncArg = {
        name: 'behavior',
        position: -1,
        optional: true,
        isNamed: true,
        valueType: 'code',
      };

      const display = argumentDisplay(argument);

      expect(display).toBe('behavior= [code]');
    });
  });

  describe('位置引数を表示する場合', () => {
    test('位置番号の後へcode型を付ける', () => {
      const argument: FuncArg = {
        name: 'command',
        position: 1,
        optional: false,
        isNamed: false,
        valueType: 'code',
      };

      const display = argumentDisplay(argument);

      expect(display).toBe('$1 [code]');
    });
  });
});
