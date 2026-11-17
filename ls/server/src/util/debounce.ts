import { createIOState } from './ioState';

export function debounce<Args extends readonly unknown[]>(
  func: (...args: Args) => void,
  waitFor?: number,
) {
  const timer = createIOState<ReturnType<typeof setTimeout> | undefined>(undefined);

  return (...args: Args): void => {
    clearTimeout(timer.read());
    timer.replace(setTimeout(() => func(...args), waitFor || 500));
  };
}
