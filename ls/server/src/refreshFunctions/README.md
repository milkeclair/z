# LSP function snapshots

The connection owns a FunctionSnapshot for its lifetime. A refresh takes the previous snapshot and returns the next value.
The hydrator retains the generic readonly AST. The functions field is a separate compatibility view for the existing mutable Func[] provider interfaces.

## Project selection

Initialization selects the first local workspace folder, then rootUri, then the legacy rootPath.
Clients without workspace information use zPath as a fallback, including its existing default of ~/.z.
Configuration changes to this fallback apply when a workspace root was not selected.
File-backed .zsh buffers inside the selected project override disk content. Other projects and URI schemes are excluded from this snapshot.

## Updates and reuse

TextDocuments emits its content-change event on both open and edits.
The connection synchronously refreshes on content changes, saves, closes and watched-file notifications.
Requests arriving immediately after an edit therefore use the updated snapshot.
Diagnostic-refresh notifications alone are coalesced, honor client capabilities, and are cancelled on shutdown.

Unchanged file entries reuse their ASTs. When every file entry and the project options are unchanged, the function snapshot and compatibility array are reused too.
Edits in files without function definitions reuse the compatibility view while replacing the changed AST entry.
Each connection creates its own empty compatibility view.

## Compatibility projection

The projection derives names, one-based declaration lines, argument metadata and legacy documentation values from the hydrated AST.
Named argument positions, rest positions and argument ordering retain the old Func[] conventions.
The legacy UI formatters consume this projected documentation, so open and new-file documentation comes from the same snapshot as the function and argument data.

Language features use the name index and cached document ASTs for call/position queries.
A separate diagnostic snapshot derives command resolution and parameter checks from the same AST, including lexer, parser and hydration diagnostics. See [diagnostics](../diagnostics/README.md).

## Verification

Run npm test in the ls directory. It first cleans the existing build output and emits the Node server before running tests.
The stdio integration tests launch that real emitted server, send LSP requests/notifications, and use temporary on-disk files plus open buffers.
