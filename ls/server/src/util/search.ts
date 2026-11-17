/** 整列済みの範囲で、条件を満たさなくなる最初の位置を返す。再帰の深さは対数になる。 */
export function lowerBound(length: number, isBefore: (index: number) => boolean): number {
  const search = (low: number, high: number): number => {
    if (low >= high) {
      return low;
    }
    const middle = Math.floor((low + high) / 2);
    return isBefore(middle) ? search(middle + 1, high) : search(low, middle);
  };
  return search(0, length);
}
