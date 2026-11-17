import { describe, expect, test } from 'vitest';
import { ansiEscape } from '../../../../src/zshParser/lexer/delimiter/heredoc';

describe('ANSI quoted escape reader', () => {
  test.each([
    [String.raw`\C-a`, '\x01', 4],
    [String.raw`\C-n`, '\x0e', 4],
    [String.raw`\C-\n`, '\n', 5],
    [String.raw`\C-\x41`, '\x01', 7],
    [String.raw`\C-x41`, '\x18', 4],
    [String.raw`\M-a`, '\xe1', 4],
    [String.raw`\M-\C-a`, '\x81', 7],
    [String.raw`\C-\M-a`, '\x81', 7],
    [String.raw`\x`, '\0', 2],
    [String.raw`\u`, '\0', 2],
    [String.raw`\q`, 'q', 2],
  ])('実Zshと同じ文字と消費範囲を返す: %s', (raw, value, end) => {
    expect(ansiEscape(raw, 0)).toMatchObject({ value, end });
  });
  test.each([String.raw`\uD800`, String.raw`\Uffffffff`])('不正なUnicode値を示す: %s', (raw) => {
    expect(ansiEscape(raw, 0).valid).toBe(false);
  });
});
