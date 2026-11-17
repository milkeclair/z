import { describe, expect, test } from 'vitest';
import { ansiEscape } from '../../../../src/zshParser/lexer/delimiter/heredoc';

describe('ansiEscape', () => {
  describe('ANSI形式のエスケープを読む場合', () => {
    test('control-aを復号して消費範囲を返す', () => {
      const raw = String.raw`\C-a`;
      const value = '\x01';
      const end = 4;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('control-nを復号して消費範囲を返す', () => {
      const raw = String.raw`\C-n`;
      const value = '\x0e';
      const end = 4;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('control付きの改行エスケープを復号する', () => {
      const raw = String.raw`\C-\n`;
      const value = '\n';
      const end = 5;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('control付きの16進エスケープを復号する', () => {
      const raw = String.raw`\C-\x41`;
      const value = '\x01';
      const end = 7;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('control文字の後の通常文字を読み過ぎない', () => {
      const raw = String.raw`\C-x41`;
      const value = '\x18';
      const end = 4;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('meta-aを復号して消費範囲を返す', () => {
      const raw = String.raw`\M-a`;
      const value = '\xe1';
      const end = 4;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('meta-controlの順のエスケープを復号する', () => {
      const raw = String.raw`\M-\C-a`;
      const value = '\x81';
      const end = 7;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('control-metaの順のエスケープを復号する', () => {
      const raw = String.raw`\C-\M-a`;
      const value = '\x81';
      const end = 7;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('数字のない16進エスケープをZshと同じ値にする', () => {
      const raw = String.raw`\x`;
      const value = '\0';
      const end = 2;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('数字のないUnicodeエスケープをZshと同じ値にする', () => {
      const raw = String.raw`\u`;
      const value = '\0';
      const end = 2;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('未知のエスケープをZshと同じ値にする', () => {
      const raw = String.raw`\q`;
      const value = 'q';
      const end = 2;

      expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
    });

    test('サロゲートを不正なUnicode値として示す', () => {
      const raw = String.raw`\uD800`;

      expect(ansiEscape(raw, 0).valid).toBe(false);
    });

    test('Unicode上限を越える値を不正として示す', () => {
      const raw = String.raw`\Uffffffff`;

      expect(ansiEscape(raw, 0).valid).toBe(false);
    });
  });
});
