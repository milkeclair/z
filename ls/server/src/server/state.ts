import type { Connection } from 'vscode-languageserver/node';
import type { PendingAnalysis } from '../connection/analysis';
import type { ShellEnvironment } from '../diagnostics/environment';
import { emptyShellEnvironment } from '../diagnostics/environment';
import type { DiagnosticSnapshot } from '../diagnostics/snapshot';
import { createDiagnosticSnapshot } from '../diagnostics/snapshot';
import type { FunctionSnapshot } from '../refreshFunctions/main';
import { createFunctionSnapshot } from '../refreshFunctions/main';
import type { IOState } from '../util/ioState';
import type { TextDocument, TextDocuments } from '../vscode_type';

export type ServerState = {
  readonly snapshot: FunctionSnapshot;
  readonly diagnosticSnapshot: DiagnosticSnapshot;
  readonly environment: ShellEnvironment;
  readonly projectRoot: string;
  readonly workspaceRoot: string;
  readonly showPrivateFunctions: boolean;
  readonly supportsRefresh: boolean;
  readonly supportsWatchRegistration: boolean;
  readonly watcherReady: boolean;
  readonly stopped: boolean;
  readonly stopRescan: (() => void) | undefined;
  readonly pendingAnalysis: PendingAnalysis | null;
  readonly analysisTimer: ReturnType<typeof setTimeout> | undefined;
  readonly diagnosticsTimer: ReturnType<typeof setTimeout> | undefined;
};

export type ServerContext = {
  readonly connection: Connection;
  readonly documents: TextDocuments<TextDocument>;
  readonly state: IOState<ServerState>;
};

export function createServerState(): ServerState {
  return {
    snapshot: createFunctionSnapshot(),
    diagnosticSnapshot: createDiagnosticSnapshot(),
    environment: emptyShellEnvironment(),
    projectRoot: '',
    workspaceRoot: '',
    showPrivateFunctions: false,
    supportsRefresh: false,
    supportsWatchRegistration: false,
    watcherReady: false,
    stopped: false,
    stopRescan: undefined,
    pendingAnalysis: null,
    analysisTimer: undefined,
    diagnosticsTimer: undefined,
  };
}
