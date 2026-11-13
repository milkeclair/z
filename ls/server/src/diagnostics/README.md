# AST-based diagnostics

## Inputs and state

A server connection owns a `FunctionSnapshot`, a `ShellEnvironment` and a
`DiagnosticSnapshot`. Initialization reads the shell environment once. Document,
watcher and configuration notifications refresh the function and diagnostic
snapshots together. Document and workspace requests read the resulting reports.

`collectFileFacts` uses the iterative syntax walker once for each changed
hydration. It records command nodes, static alias/autoload declarations,
documentation usage and lexer/parser/documentation diagnostics. Function usage
has its own traversal frame, so nested function parameters belong to that
function. The existing semantic references share syntax nodes and are not
visited twice.

`refreshDiagnosticSnapshot` reuses unchanged facts and reports. Changes to
function definitions or alias/autoload declarations rebind calls in other files.
Reports retain AST references rather than copying syntax trees. An external open
document has local declarations and diagnostics; its declarations and report
stay outside project-wide enumeration.

## Shell name resolution

`readShellEnvironment` starts one interactive Zsh child with a fixed query.
It loads the user's normal shell startup environment and reads names from the
command, builtin, alias and function tables. Registered autoload functions appear
in the function table without executing their bodies. Global and suffix aliases
and `POSIX_BUILTINS` are recorded too.

The query has a three-second timeout and a two-MiB combined output limit. On
Unix the child owns a process group, which is terminated on completion or
failure, including normal exit of the calling Node process. A failed query leaves environment-dependent names unresolved; known
project-function argument checks still work. A server restart refreshes changes
to the runtime environment.

Normal calls resolve aliases, project functions, shell functions, autoloads,
builtins and external commands. `builtin` selects builtins. `command` selects
external commands, with builtin fallback when `POSIX_BUILTINS` is enabled.
`exec` can invoke functions and builtins. `command -v/-V` queries names, so it
does not produce execution diagnostics.

Static project `alias` and `autoload` declarations supplement the captured
environment. Alias calls are recognized as macros and their expanded argument
lists are left unresolved. The analyzer does not execute project files or
autoload bodies. Runtime changes to PATH, shell options and declarations can
differ from these static inputs.

Absolute executable paths are checked for file type and execution permission.
Existing executable paths relative to the project root are recognized. A missing
relative path remains unresolved because the script's working directory may
change. Glob, tilde, equals and dynamic command-name expansions also remain
unresolved. An unknown static name produces `undefined-command` only when the
shell environment was obtained successfully.

## Parameter contracts

Required arguments come from `documentationOf(definition).parameters`. Each
syntax word supplies one positional argument unless it has a documented bare
`name=value` key. Position numbers, optional parameters and rest parameters are
read directly from documentation nodes. A required `$3` needs three positional
words even if `$1` and `$2` are absent from the documentation.

Quoted scalar values count as one word. Words whose expansions or global aliases
may supply an unknown number of arguments defer the missing-argument checks.
Files with incomplete syntax also defer these checks while retaining syntax diagnostics.
This is a syntax-based contract check, rather than runtime shell evaluation.

Unused-argument warnings point to the documentation marker range. Actual
parameter/variable references, static named hash access and `z.arg.named` retrieval
count as uses. `$@` and `$*` forwarding conservatively consume all parameters.
Literal text, comments and nested function bodies do not count as outer uses.
Opaque expressions, complex parameter expansions, expanding here-documents and
incomplete syntax defer unused-argument warnings because usage cannot be
established from the current AST representation.

## Controls and reports

`zls: ignore` is read from hydrated comment directives. It suppresses diagnostics
starting on that physical line. Optional arguments select diagnostic codes, for
example `# zls: ignore missing-positional-argument`. Text inside strings and
documentation examples has no suppression effect.

Lexer, parser and documentation diagnostics retain separate sources. Formatting
checks use syntax whitespace and exact source positions. Workspace reports
include unsaved project files and their open versions; closed files use a null
version. Reports include a result ID so clients can return their previous URI/ID
pairs. Previous workspace result URIs that disappeared receive empty reports.

Tests exercise a real Zsh environment and a compiled Node server over stdio,
alongside AST ownership, argument contracts, controls and snapshot reuse.
