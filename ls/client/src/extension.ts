import {
  LanguageClient,
  TransportKind,
  ServerOptions,
  LanguageClientOptions,
} from 'vscode-languageclient/node';
import { workspace, ExtensionContext } from 'vscode';
import path from 'path';

let client: LanguageClient;

export function activate(context: ExtensionContext) {
  const serverModule = context.asAbsolutePath(path.join('server', 'dist', 'server.js'));
  const serverOptions: ServerOptions = {
    run: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: { cwd: path.dirname(serverModule) },
    },
    debug: {
      module: serverModule,
      transport: TransportKind.ipc,
      options: { cwd: path.dirname(serverModule) },
    },
  };

  const zPath = workspace.getConfiguration('z-ls').get('zPath');

  const clientOptions: LanguageClientOptions = {
    documentSelector: [{ scheme: 'file', language: 'shellscript' }],
    synchronize: {
      fileEvents: workspace.createFileSystemWatcher('**/*.{zsh}'),
    },
    initializationOptions: { zPath },
  };

  client = new LanguageClient('z-ls', 'z-ls', serverOptions, clientOptions);
  client.start();
}

export function deactivate() {
  if (!client) {
    return undefined;
  }
  return client.stop();
}
