export function debounce<F extends (...args: any[]) => void>(func: F, waitFor?: number) {
  let timeout: NodeJS.Timeout;
  const defaultDelay = 500;

  return (...args: Parameters<F>) => {
    clearTimeout(timeout);
    timeout = setTimeout(() => func(...args), waitFor || defaultDelay);
  };
}
