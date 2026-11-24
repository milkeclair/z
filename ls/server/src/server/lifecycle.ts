import type { DidChangeConfigurationParams, InitializeParams } from 'vscode-languageserver/node';
import { projectRootFromSettings } from '../connection/projectRoot';
import { startPeriodicRescan } from '../connection/rescan';
import { readShellEnvironment } from '../diagnostics/environment';
import { refreshDiagnosticSnapshot } from '../diagnostics/snapshot';
import { refreshFunctionSnapshot } from '../refreshFunctions/main';
import { zInitialize, zSettingsFromConfigurationNotification } from '../main';
import { DidChangeWatchedFilesNotification } from '../vscode_type';
import { flushAnalysis, refreshAll, scheduleAnalysis, scheduleUriChanges } from './analysis';
import type { ServerContext } from './state';

async function initializeServer(context: ServerContext, params: InitializeParams) {
  const { state, connection } = context;

  const initialized = zInitialize(params);
  state.update((previous) => ({
    ...previous,
    projectRoot: initialized.projectRoot,
    workspaceRoot: initialized.workspaceRoot,
    snapshot: initialized.snapshot,
  }));
  const environment = await readShellEnvironment();

  if (environment.kind === 'unavailable') {
    connection.console.warn('Shell environment unavailable: ' + environment.reason);
  }

  const current = state.read();
  const snapshot = refreshFunctionSnapshot({
    projectRoot: current.projectRoot,
    documents: context.documents,
    previous: current.snapshot,
    changedPaths: [],
    functionSources: environment.kind === 'available' ? environment.functionSources : undefined,
  });
  state.replace({
    ...current,
    environment,
    snapshot,
    diagnosticSnapshot: refreshDiagnosticSnapshot({ snapshot, environment }),
    showPrivateFunctions: initialized.settings.completion.showPrivateFunctions,
    supportsRefresh: params.capabilities.workspace?.diagnostics?.refreshSupport === true,
    supportsWatchRegistration:
      params.capabilities.workspace?.didChangeWatchedFiles?.dynamicRegistration === true,
  });

  return initialized.serverCapabilities;
}

function startWatching(context: ServerContext) {
  const { state, connection } = context;

  const current = state.read();

  if (current.stopped) {
    return;
  }

  current.stopRescan?.();
  const stopRescan = startPeriodicRescan(
    () => {
      if (state.read().projectRoot) {
        refreshAll(context);
      }
    },
    (error) => connection.console.error('Periodic rescan failed: ' + String(error)),
  );
  state.update((previous) => ({ ...previous, stopRescan }));

  if (current.supportsWatchRegistration) {
    void connection.client
      .register(DidChangeWatchedFilesNotification.type, {
        watchers: [{ globPattern: '**/*.zsh' }],
      })
      .then(() => {
        if (state.read().stopped) {
          return;
        }

        refreshAll(context);
        state.update((previous) => ({
          ...previous,
          watcherReady:
            previous.workspaceRoot !== '' && previous.projectRoot === previous.workspaceRoot,
        }));
      })
      .catch((error: unknown) =>
        connection.console.warn('File watcher registration failed: ' + String(error)),
      );
  }
}

function applyConfiguration(context: ServerContext, params: DidChangeConfigurationParams) {
  const { state } = context;

  const settings = zSettingsFromConfigurationNotification(params.settings);
  state.update((previous) => ({
    ...previous,
    showPrivateFunctions: settings.completion.showPrivateFunctions,
  }));
  refreshAll(context, projectRootFromSettings(state.read().workspaceRoot, settings.zPath));
}

function stopServer(context: ServerContext) {
  const { state } = context;

  const current = state.read();
  state.replace({ ...current, stopped: true, stopRescan: undefined, pendingAnalysis: null });
  current.stopRescan?.();
  clearTimeout(current.analysisTimer);
  clearTimeout(current.diagnosticsTimer);
}

function synchronizeDocument(context: ServerContext, uri: string): void {
  scheduleUriChanges(context, [uri]);
  flushAnalysis(context);
}

export function registerServerLifecycle(context: ServerContext): void {
  const { connection, documents } = context;

  connection.onInitialize((params) => initializeServer(context, params));
  connection.onInitialized(() => startWatching(context));
  connection.onDidChangeConfiguration((params) => applyConfiguration(context, params));
  connection.onShutdown(() => stopServer(context));

  connection.onDidChangeWatchedFiles((params) =>
    scheduleUriChanges(
      context,
      params.changes.map((change) => change.uri),
    ),
  );
  documents.onDidChangeContent(() => scheduleAnalysis(context, []));
  documents.onDidSave((event) => synchronizeDocument(context, event.document.uri));
  documents.onDidClose((event) => synchronizeDocument(context, event.document.uri));
}
