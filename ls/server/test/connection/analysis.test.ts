import { describe, expect, test } from 'vitest';
import { queueAnalysis, analysisDelay } from '../../src/connection/analysis';

describe('pending analysis', () => {
  test('bufferのみの変更を保持し、パスの重複をまとめ、過去状態を変更しない', () => {
    const first = queueAnalysis(null, [], 0);
    const changed = queueAnalysis(first, ['a.zsh', 'b.zsh', 'a.zsh'], 20);
    const next = queueAnalysis(changed, ['b.zsh', 'c.zsh'], 40);
    expect(first).toEqual({ since: 0, changedPaths: [] });
    expect(changed).toEqual({ since: 0, changedPaths: ['a.zsh', 'b.zsh'] });
    expect(next).toEqual({ since: 0, changedPaths: ['a.zsh', 'b.zsh', 'c.zsh'] });
  });

  test('全同期要求は後続のパス変更やbuffer変更に対して保持する', () => {
    const first = queueAnalysis(null, ['a.zsh'], 0);
    const full = queueAnalysis(first, undefined, 20);
    expect(full).toEqual({ since: 0, changedPaths: undefined });
    expect(queueAnalysis(full, [], 40)).toEqual(full);
    expect(queueAnalysis(full, ['b.zsh'], 50)).toEqual(full);
    expect(queueAnalysis(null, undefined, 60)).toEqual({ since: 60, changedPaths: undefined });
  });

  test.each([[0, 50], [100, 50], [170, 30], [199, 1], [200, 0], [250, 0]])(
    '連続編集でも最初の変更から200msを超えて予約を先延ばしにしない: now=%i', (now, delay) => {
      const first = queueAnalysis(null, [], 0);
      const next = queueAnalysis(first, ['a.zsh'], now);
      expect(next.since).toBe(0);
      expect(analysisDelay(next, now)).toBe(delay);
    });

  test('flush後の新しい変更では待機の開始時刻を取り直す', () => {
    const next = queueAnalysis(null, [], 1000);
    expect(analysisDelay(next, 1000)).toBe(50);
    expect(analysisDelay(next, 1190)).toBe(10);
  });
});
