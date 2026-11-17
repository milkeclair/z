import { List, Range } from 'immutable';

export function levenshteinDistance(source: string, target: string): number {
  const firstRow = List(Range(0, target.length + 1));
  const lastRow = Range(1, source.length + 1).reduce(
    (previous, row) =>
      Range(1, target.length + 1).reduce(
        (current, column) => {
          const substitution =
            previous.get(column - 1, 0) +
            (source.charAt(row - 1) === target.charAt(column - 1) ? 0 : 1);
          const insertion = current.last(0) + 1;
          const deletion = previous.get(column, 0) + 1;
          return current.push(Math.min(substitution, insertion, deletion));
        },
        List([row]),
      ),
    firstRow,
  );
  return lastRow.last(0);
}

export function findClosestMatch(
  target: string,
  candidates: readonly string[],
  threshold = 3,
): string | null {
  const best = candidates.reduce<{ readonly distance: number; readonly name: string | null }>(
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
