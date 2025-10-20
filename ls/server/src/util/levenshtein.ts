export function levenshteinDistance(str1: string, str2: string): number {
  const memoTable: number[][] = [];

  const initRow = () => {
    for (let row = 0; row <= str1.length; row++) {
      memoTable[row] = [row];
    }
  };

  const initCol = () => {
    for (let col = 0; col <= str2.length; col++) {
      memoTable[0][col] = col;
    }
  };

  const eachRow = (fn: (row: number) => void) => {
    for (let row = 1; row <= str1.length; row++) {
      fn(row);
    }
  };

  const eachCol = (fn: (col: number) => void) => {
    for (let col = 1; col <= str2.length; col++) {
      fn(col);
    }
  };

  const matchChar = (row: number, col: number): boolean => {
    return str1.charAt(row - 1) === str2.charAt(col - 1);
  };

  const replaceChar = (row: number, col: number): number => {
    const diagonal = memoTable[row - 1][col - 1];
    const cost = 1;

    return diagonal + cost;
  };

  const insertChar = (row: number, col: number): number => {
    const left = memoTable[row][col - 1];
    const cost = 1;

    return left + cost;
  };

  const deleteChar = (row: number, col: number): number => {
    const upper = memoTable[row - 1][col];
    const cost = 1;

    return upper + cost;
  };

  initRow();
  initCol();

  eachRow((row) => {
    eachCol((col) => {
      if (matchChar(row, col)) {
        const diagonal = memoTable[row - 1][col - 1];

        memoTable[row][col] = diagonal;
      } else {
        memoTable[row][col] = Math.min(
          replaceChar(row, col),
          insertChar(row, col),
          deleteChar(row, col)
        );
      }
    });
  });

  const result = memoTable[str1.length][str2.length];
  return result;
}

export function findClosestMatch(
  target: string,
  candidates: string[],
  threshold: number = 3
): string | null {
  let minDistance = Infinity;
  let closestMatch: string | null = null;

  for (const candidate of candidates) {
    const distance = levenshteinDistance(target, candidate);
    const withinThreshold = distance <= threshold;
    const closerThanBefore = distance < minDistance;

    if (withinThreshold && closerThanBefore) {
      minDistance = distance;
      closestMatch = candidate;
    }
  }

  return closestMatch;
}
