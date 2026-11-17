import { flushAnalysis } from './server/analysis';
import { registerServerLifecycle } from './server/lifecycle';
import { registerLanguageFeatures } from './server/providers';
import { createServerState, type ServerContext } from './server/state';
import { createIOState } from './util/ioState';
import { createConnection, ProposedFeatures, TextDocument, TextDocuments } from './vscode_type';

function currentLanguageState(context: ServerContext) {
  flushAnalysis(context);
  const { snapshot, diagnosticSnapshot, showPrivateFunctions } = context.state.read();

  return { snapshot, diagnosticSnapshot, showPrivateFunctions };
}

function startServer(): void {
  const connection = createConnection(ProposedFeatures.all);
  const documents = new TextDocuments(TextDocument);
  const context: ServerContext = {
    connection,
    documents,
    state: createIOState(createServerState()),
  };

  registerServerLifecycle(context);
  registerLanguageFeatures({
    connection,
    documents,
    currentState: () => currentLanguageState(context),
  });

  documents.listen(connection);
  connection.listen();
}

startServer();
