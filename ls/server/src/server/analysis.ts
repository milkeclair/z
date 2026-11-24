import { performance } from 'node:perf_hooks';
import { fileURLToPath } from 'node:url';
import { analysisDelay, queueAnalysis } from '../connection/analysis';
import { refreshDiagnosticSnapshot } from '../diagnostics/snapshot';
import { refreshFunctionSnapshot } from '../refreshFunctions/main';
import type { ServerContext } from './state';

function localFilePaths(uris: readonly string[]): readonly string[] {
  return uris.flatMap((uri) => {
    try {
      return [fileURLToPath(uri)];
    } catch {
      return [];
    }
  });
}

export function scheduleUriChanges(context: ServerContext, uris: readonly string[]): void {
  scheduleAnalysis(context, localFilePaths(uris));
}

function scheduleDiagnosticsRefresh(context: ServerContext): void {
  const { state, connection } = context;

  const current = state.read();

  if (!current.supportsRefresh) {
    return;
  }

  clearTimeout(current.diagnosticsTimer);
  const timer = setTimeout(() => {
    state.update((previous) => ({ ...previous, diagnosticsTimer: undefined }));
    void connection.languages.diagnostics.refresh().catch((error: unknown) => {
      connection.console.warn('Diagnostic refresh failed: ' + String(error));
    });
  }, 500);
  state.update((previous) => ({ ...previous, diagnosticsTimer: timer }));
}

function refreshAnalysis(
  context: ServerContext,
  root = context.state.read().projectRoot,
  changedPaths?: readonly string[],
): void {
  const { state, documents } = context;

  const current = state.read();
  const snapshot = refreshFunctionSnapshot({
    projectRoot: root,
    documents,
    previous: current.snapshot,
    functionSources:
      current.environment.kind === 'available' ? current.environment.functionSources : undefined,
    changedPaths: current.watcherReady ? changedPaths : undefined,
  });
  const diagnosticSnapshot = refreshDiagnosticSnapshot({
    snapshot,
    environment: current.environment,
    previous: current.diagnosticSnapshot,
  });
  state.replace({ ...current, snapshot, diagnosticSnapshot, projectRoot: root });
  scheduleDiagnosticsRefresh(context);
}

export function flushAnalysis(context: ServerContext): void {
  const { state } = context;

  const current = state.read();
  clearTimeout(current.analysisTimer);
  state.update((previous) => ({ ...previous, analysisTimer: undefined }));

  if (!current.pendingAnalysis) {
    return;
  }

  refreshAnalysis(context, current.projectRoot, current.pendingAnalysis.changedPaths);
  state.update((previous) => ({ ...previous, pendingAnalysis: null }));
}

export function scheduleAnalysis(
  context: ServerContext,
  changedPaths: readonly string[] | undefined,
): void {
  const { state, connection } = context;

  const current = state.read();

  if (current.stopped) {
    return;
  }

  const now = performance.now();
  const pendingAnalysis = queueAnalysis(
    current.pendingAnalysis,
    current.watcherReady ? changedPaths : undefined,
    now,
  );
  clearTimeout(current.analysisTimer);
  const timer = setTimeout(
    () => {
      try {
        flushAnalysis(context);
      } catch (error: unknown) {
        connection.console.error('Analysis refresh failed: ' + String(error));
      }
    },
    analysisDelay(pendingAnalysis, now),
  );
  state.replace({ ...current, pendingAnalysis, analysisTimer: timer });
}

export function refreshAll(context: ServerContext, root = context.state.read().projectRoot): void {
  const { state } = context;

  clearTimeout(state.read().analysisTimer);
  state.update((previous) => ({ ...previous, analysisTimer: undefined }));
  refreshAnalysis(context, root);
  state.update((previous) => ({ ...previous, pendingAnalysis: null }));
}
