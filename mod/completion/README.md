# z.completion

A modifier for completing z function names and showing function docs in zsh completion.

## Installation

`z.install.mod completion`

This also installs `job` when it is missing.

## Overview

`z.completion` registers zsh completion definitions for public `z.*` functions.

Use it when you want terminal-side completion for z functions without starting the language server.

## Setup

Call `z.completion.enable` after zsh completion is available.

```zsh
z.completion.enable
```

## Behavior

### Function name completion

For `z.<Tab>`, completion lists root namespaces such as `z.arg.` and `z.str.` once each.
Selecting a namespace keeps the trailing dot and does not insert a space, so you can continue completing within it.
For a deeper prefix such as `z.str.` or `z.str.color.`, completion lists all matching public functions, including deeper descendants.
Each candidate is displayed on its own line, both in command and argument positions.
Aliases and external commands remain available as candidates.
Other commands use the previously registered command completion.

```zsh
z.arg.na<Tab>
# => z.arg.named
# => z.arg.named.shift
```

### Docs message

```zsh
z.arg.named <Tab>
# shows docs for z.arg.named
```

Docs highlight argument names in cyan, the `REPLY`, `return`, and `example`
headings in yellow, and indented examples in green. Other text keeps the terminal default color.

Function name completion takes priority.
For example, `z.arg.n<Tab>` shows function candidates and does not show docs in the same completion attempt.

## Cache

`z.completion.enable` builds the function name synchronously, then starts a background job to build the docs cache.

Unfinished docs jobs are cancelled when the shell exits or completion is enabled again.
Jobs that have already finished keep their results available for collection.

The cache variables are:

- `z_completion_function_names`
  - public z function names used for candidate completion
- `z_completion_docs`
  - docs indexed by function name
- `z_completion_cache_ready`
  - whether the docs cache has finished loading
