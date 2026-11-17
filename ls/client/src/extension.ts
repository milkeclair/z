import path from 'node:path';
import { workspace, type ExtensionContext } from 'vscode';
import {
  LanguageClient,
  TransportKind,
  type LanguageClientOptions,
  type NodeModule,
  type ServerOptions,
} from 'vscode-languageclient/node';

let client: LanguageClient;

function createServerLaunch(serverModule: string): NodeModule {
  return {
    module: serverModule,
    transport: TransportKind.ipc,
    options: {
      cwd: path.dirname(serverModule),
      execArgv: ['--no-allocation-site-pretenuring'],
    },
  };
}

function createServerOptions(context: ExtensionContext): ServerOptions {
  const serverModule = context.asAbsolutePath(path.join('server', 'dist', 'server.js'));
  return {
    run: createServerLaunch(serverModule),
    debug: createServerLaunch(serverModule),
  };
}

function createClientOptions(): LanguageClientOptions {
  const configuration = workspace.getConfiguration('z-ls');
  return {
    documentSelector: [{ scheme: 'file', language: 'shellscript' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.{zsh}'),
      configurationSection: 'z-ls',
    },
    initializationOptions: {
      zPath: configuration.get<string>('zPath'),
      completion: {
        showPrivateFunctions:
          configuration.get<boolean>('completion.showPrivateFunctions') ?? false,
      },
    },
  };
}

export function activate(context: ExtensionContext): void {
  client = new LanguageClient('z-ls', 'z-ls', createServerOptions(context), createClientOptions());
  void client.start();
}

export function deactivate() {
  return client?.stop();
}
