import { describe, expect, test } from 'vitest';
import { disjoint } from '../../../src/connection/semanticTokens/disjoint';
import type { Span } from '../../../src/connection/semanticTokens/types';

describe('disjoint', () => {
  describe('範囲が重ならない場合', () => {
    test('空の入力から空の配列を返す', () => {
      expect(disjoint([])).toEqual([]);
    });

    test('入力順にかかわらずソース位置の順に返す', () => {
      const spans: readonly Span[] = [
        { start: 10, end: 15, type: 'function', priority: 20 },
        { start: 0, end: 5, type: 'string', priority: 10 },
      ];

      expect(disjoint(spans)).toEqual([spans[1], spans[0]]);
      expect(spans[0].start).toBe(10);
    });
  });

  describe('範囲が重なる場合', () => {
    test('優先度の高い範囲を選び、外側の残りも保持する', () => {
      const spans: readonly Span[] = [
        { start: 0, end: 10, type: 'string', priority: 10 },
        { start: 3, end: 7, type: 'function', priority: 20 },
      ];

      expect(disjoint(spans)).toEqual([
        { start: 0, end: 3, type: 'string', priority: 10 },
        { start: 3, end: 7, type: 'function', priority: 20 },
        { start: 7, end: 10, type: 'string', priority: 10 },
      ]);
    });

    test('同じ優先度なら先に有効になった範囲を選ぶ', () => {
      const spans: readonly Span[] = [
        { start: 0, end: 10, type: 'string', priority: 10 },
        { start: 3, end: 7, type: 'function', priority: 10 },
      ];

      expect(disjoint(spans)).toEqual([spans[0]]);
    });
  });

  describe('隣接する範囲を返す場合', () => {
    test('同じ種類の範囲を結合する', () => {
      const spans: readonly Span[] = [
        { start: 0, end: 5, type: 'string', priority: 10 },
        { start: 5, end: 10, type: 'string', priority: 20 },
      ];

      expect(disjoint(spans)).toEqual([{ start: 0, end: 10, type: 'string', priority: 10 }]);
    });

    test('異なる種類の範囲は分けて保持する', () => {
      const spans: readonly Span[] = [
        { start: 0, end: 5, type: 'string', priority: 10 },
        { start: 5, end: 10, type: 'function', priority: 20 },
      ];

      expect(disjoint(spans)).toEqual(spans);
    });
  });
});
