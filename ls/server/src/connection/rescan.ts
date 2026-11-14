export function startPeriodicRescan(refresh: () => void, onError: (error: unknown) => void): () => void {
  const timer = setInterval(() => {
    try { refresh(); }
    catch (error: unknown) { onError(error); }
  }, 60_000);
  timer.unref();
  return () => clearInterval(timer);
}
