import { appendItems, collectArray, numberRange } from './collections';
export function levenshteinDistance(source: string, target: string): number {
  const firstRow = collectArray(numberRange(0, target.length + 1));
  const lastRow = numberRange(1, source.length + 1).reduce(
    (previous, row) =>
      numberRange(1, target.length + 1).reduce(
        (current, column) => {
          const substitution =
            (previous.at(column - 1) ?? 0) +
            (source.charAt(row - 1) === target.charAt(column - 1) ? 0 : 1);
          const insertion = (current.at(-1) ?? 0) + 1;
          const deletion = (previous.at(column) ?? 0) + 1;

          return appendItems(current, Math.min(substitution, insertion, deletion));
        },
        collectArray([row]),
      ),
    firstRow,
  );

  return lastRow.at(-1) ?? 0;
}

export function findClosestMatch(
  target: string,
  candidates: readonly string[],
  threshold = 3,
): string | null {
  const best = candidates.reduce<{
    readonly distance: number;
    readonly name: string | null;
  }>(
    (previous, candidate) => {
      const distance = levenshteinDistance(target, candidate);

      return distance <= threshold && distance < previous.distance
        ? { distance, name: candidate }
        : previous;
    },
    { distance: Infinity, name: null },
  );

  return best.name;
}
