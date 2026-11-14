import { afterEach, describe, expect, test, vi } from 'vitest';
import { startPeriodicRescan } from '../../src/connection/rescan';

afterEach(() => { vi.useRealTimers(); });

describe('periodic full rescan', () => {
  test('最初の走査を60秒後に行い、その後も60秒間隔で繰り返す', () => {
    vi.useFakeTimers();
    const refresh = vi.fn();
    const report = vi.fn();
    const stop = startPeriodicRescan(refresh, report);
    vi.advanceTimersByTime(59_999);
    expect(refresh).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(refresh).toHaveBeenCalledTimes(1);
    vi.advanceTimersByTime(120_000);
    expect(refresh).toHaveBeenCalledTimes(3);
    expect(report).not.toHaveBeenCalled();
    stop();
    expect(vi.getTimerCount()).toBe(0);
  });

  test('走査エラーを通知し、次の周期でも再び走査する', () => {
    vi.useFakeTimers();
    const error = new Error('temporary disk failure');
    const refresh = vi.fn().mockImplementationOnce(() => { throw error; });
    const report = vi.fn();
    const stop = startPeriodicRescan(refresh, report);
    vi.advanceTimersByTime(60_000);
    expect(report).toHaveBeenCalledExactlyOnceWith(error);
    vi.advanceTimersByTime(60_000);
    expect(refresh).toHaveBeenCalledTimes(2);
    expect(report).toHaveBeenCalledTimes(1);
    stop();
  });

  test('初回前に停止した場合は走査せず、タイマーを解除する', () => {
    vi.useFakeTimers();
    const refresh = vi.fn();
    const stop = startPeriodicRescan(refresh, vi.fn());
    vi.advanceTimersByTime(59_999);
    stop();
    vi.advanceTimersByTime(120_000);
    expect(refresh).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
  });

  test('停止操作を繰り返しても、別接続の定期走査は続ける', () => {
    vi.useFakeTimers();
    const first = vi.fn();
    const second = vi.fn();
    const stopFirst = startPeriodicRescan(first, vi.fn());
    const stopSecond = startPeriodicRescan(second, vi.fn());
    vi.advanceTimersByTime(60_000);
    stopFirst();
    stopFirst();
    vi.advanceTimersByTime(60_000);
    expect(first).toHaveBeenCalledTimes(1);
    expect(second).toHaveBeenCalledTimes(2);
    expect(vi.getTimerCount()).toBe(1);
    stopSecond();
    expect(vi.getTimerCount()).toBe(0);
  });
});
