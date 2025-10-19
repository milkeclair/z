import os from 'os';
import { InitializeParams } from 'vscode-languageserver';
import { Func } from '../getFunctions/type';
import { getAllZFunctions } from '../getFunctions/main';
import { serverCapability } from '../serverCapability/main';

export function zInitialize(params: InitializeParams): {
  projectRoot: string;
  functions: Func[];
  serverCapabilities: ReturnType<typeof serverCapability>;
} {
  const libPath: string = params.initializationOptions.zPath || '';
  const projectRoot = libPath.replace(/^~/, os.homedir());
  const functions = getAllZFunctions(projectRoot);

  return {
    projectRoot: projectRoot,
    functions: functions,
    serverCapabilities: serverCapability(),
  };
}
