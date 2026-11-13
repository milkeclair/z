# AST-based language features

## Snapshot

Each server connection owns a `FunctionSnapshot`:

- `hydrator` holds project files with hydrated syntax trees and documentation.
- `targets` maps a static function name to its definition and exact name node.
- `documents` maps each open local `.zsh` URI to its version, content and hydration.
- `functions` provides the existing display/diagnostic compatibility view.

A project document and its function targets reference the same hydrated tree.
An open document outside the project receives its own cached hydration for cursor
queries; project files supply the definitions offered by language features.
Closing an external document releases that entry.

`refreshFunctionSnapshot` takes the previous snapshot and returns the next one.
Unchanged document entries retain their identity. Editing only a caller reuses
the function index and compatibility view.

## Cursor and function queries

`cursorAt` checks the document version, locates the syntax path, and uses the
token table to handle a caret at EOF or after whitespace. Token lookup uses
binary search. `callAt` selects the nearest simple command within its command
substitution or subshell boundary.

Completion replaces a static command word. An empty command slot is determined
from AST ownership and the adjacent token. Names containing shell syntax are
quoted on insertion. Multiline command words yield no completion edit because
LSP completion edits must stay on one line.

Hover and definition resolve actual command names and declaration names.
Definition locations use the exact name range and an encoded file URI. Duplicate
names prefer the nearest preceding definition in the same file, then another
definition in that file, then the first indexed project definition. Completion
and its documentation use the same choice.

Comments, redirect targets, here-document contents and opaque expressions yield
no function-name actions. Explicit `builtin`, `command` and `exec` modifiers
select execution outside project function resolution.

## Argument documentation

Signature help and call-argument hover use `SimpleCommand.arguments`. A quoted
or multiline argument remains one syntax word. Bare documented `name=value`
arguments select their named parameter; positional words select their ordinal
parameter and then a documented rest parameter. This describes syntax words;
runtime expansion can produce a different number of shell arguments.

Within a function, argument hover recognizes direct positional parameter parts
and simple aliases declared with `$1`, `${1}`, static named hash access, or the
`REPLY` immediately following `z.arg.named ... &&`. Alias lookup visits preceding
commands in enclosing list scopes with the existing iterative AST walker.
A later direct assignment replaces the earlier alias. This is a local syntax
query, rather than shell control-flow evaluation.

Expression details retained as raw parameter/arithmetic expansions stay within
the parser's existing representation. Semantic diagnostics continue to consume
the compatibility view as a separate migration stage.

## Resources and verification

Language-feature requests reuse cached syntax and documentation. Their temporary
state consists of cursor paths, lookup candidates and result items. Alias lookup
visits the enclosing function and uses stack-safe traversal. Completion enumerates
indexed names; definition and hover look up one name before choosing a candidate.
No request reads source files from disk or invokes the lexer.

Tests cover cursor ownership, quoted names, exact locations, multiline arguments,
alias scopes and snapshot identity. The stdio tests start the compiled Node server
and exercise document notifications and protocol requests through the SDK client.
