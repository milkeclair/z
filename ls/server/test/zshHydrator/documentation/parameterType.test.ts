import { describe, expect, test } from 'vitest';
import { parseCodeParameterType } from '../../../src/zshHydrator/documentation/parameterType';

describe('code parameter type reader', () => {
  test('指定位置から閉じ角括弧までを読む', () => {
    expect(parseCodeParameterType("xx[code | 'call_original'] tail", 2)).toEqual({
      end: 26, literalValues: ['call_original'],
    });
  });
  test('引用内のpipeとescaped quoteをliteralとして保持する', () => {
    const text = String.raw`[code | 'a|b' | 'it\'s' | "a\\b"]`;
    expect(parseCodeParameterType(text, 0)?.literalValues).toEqual(['a|b', "it's", String.raw`a\b`]);
  });
  test.each(['[unknown]', '[code | ]', "[code | 'x'", '[code extra]', '[code | value]'])(
    '不完全な型を受け付けない: %s', text => {
      expect(parseCodeParameterType(text, 0)).toBeNull();
    },
  );
});
