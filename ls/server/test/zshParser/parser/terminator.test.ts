import { describe, expect, test } from 'vitest';
import { parse } from './helper';

describe('Parser.parse', () => {
  describe('終端を解析する場合', () => {
    test('background系terminatorをListItemに保持する', () => {
      const result = parse('a & b &| c &!\n');

      expect(result.ast.body.items.map((item) => item.terminator?.type ?? null)).toEqual([
        'background',
        'backgroundPipe',
        'backgroundBang',
      ]);
    });
  });
});
