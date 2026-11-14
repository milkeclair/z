export type PendingAnalysis = {
  readonly since: number;
  readonly changedPaths: readonly string[] | undefined;
};

export function queueAnalysis(previous: PendingAnalysis | null,
  changedPaths: readonly string[] | undefined, now: number): PendingAnalysis {
  return { since: previous?.since ?? now,
    changedPaths: changedPaths === undefined || previous && previous.changedPaths === undefined
      ? undefined : [...new Set([...(previous?.changedPaths ?? []), ...changedPaths])] };
}

export function analysisDelay(pending: PendingAnalysis, now: number): number {
  return Math.max(0, Math.min(50, pending.since + 200 - now));
}
