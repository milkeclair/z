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

When the current word starts with `z.`, completion lists matching public z functions.

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

Function name completion takes priority.
For example, `z.arg.n<Tab>` shows function candidates and does not show docs in the same completion attempt.

## Cache

`z.completion.enable` builds the function name synchronously, then starts a background job to build the docs cache.

The cache variables are:

- `z_completion_function_names`
  - public z function names used for candidate completion
- `z_completion_docs`
  - docs indexed by function name
- `z_completion_cache_ready`
  - whether the docs cache has finished loading
