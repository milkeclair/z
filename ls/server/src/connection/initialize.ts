import { InitializeParams } from '../vscode_type';
import { Func } from '../getFunctions/type';
import { refreshFunctionSnapshot, type FunctionSnapshot } from '../refreshFunctions/main';
import { projectRootFromSettings, workspaceProjectRoot } from './projectRoot';
import { serverCapability } from '../serverCapability/main';

export type ZLsSettings = {
  zPath: string;
  completion: {
    showPrivateFunctions: boolean;
  };
};

const DEFAULT_Z_PATH = '~/.z';
const DEFAULT_SHOW_PRIVATE_FUNCTIONS = false;

type UnknownRecord = Record<string, unknown>;

function isRecord(value: unknown): value is UnknownRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function readObject(value: unknown, key: string): UnknownRecord {
  if (!isRecord(value)) return {};

  const child = value[key];
  return isRecord(child) ? child : {};
}

function readString(value: unknown, key: string, defaultValue: string): string {
  if (!isRecord(value)) return defaultValue;

  const child = value[key];
  return typeof child === 'string' ? child : defaultValue;
}

function readBoolean(value: unknown, key: string, defaultValue: boolean): boolean {
  if (!isRecord(value)) return defaultValue;

  const child = value[key];
  return typeof child === 'boolean' ? child : defaultValue;
}

export function zSettingsFromInitializationOptions(value: unknown): ZLsSettings {
  const completion = readObject(value, 'completion');

  return {
    zPath: readString(value, 'zPath', DEFAULT_Z_PATH),
    completion: {
      showPrivateFunctions: readBoolean(
        completion,
        'showPrivateFunctions',
        DEFAULT_SHOW_PRIVATE_FUNCTIONS
      ),
    },
  };
}

export function zSettingsFromConfigurationNotification(value: unknown): ZLsSettings {
  if (!isRecord(value)) return zSettingsFromInitializationOptions({});

  return zSettingsFromInitializationOptions(value['z-ls']);
}

export function zInitialize(params: InitializeParams): {
  projectRoot: string;
  workspaceRoot: string;
  snapshot: FunctionSnapshot;
  functions: Func[];
  settings: ZLsSettings;
  serverCapabilities: ReturnType<typeof serverCapability>;
} {
  const settings = zSettingsFromInitializationOptions(params.initializationOptions);
  const workspaceRoot = workspaceProjectRoot(params);
  const projectRoot = projectRootFromSettings(workspaceRoot, settings.zPath);
  const snapshot = refreshFunctionSnapshot({ projectRoot, documents: [] });

  return {
    projectRoot,
    workspaceRoot,
    snapshot,
    functions: snapshot.functions,
    settings: settings,
    serverCapabilities: serverCapability(),
  };
}
