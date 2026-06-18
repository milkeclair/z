# z.wt_proxy

A modifier for running Docker Compose projects from multiple git worktrees without port conflicts.

## Installation

`z.install.mod wt_proxy`

This also installs `git` when it is missing.

## Overview

Each worktree can run Docker Compose with its own port values.

```zsh
z.wt_proxy.init
z.wt_proxy.start
z.wt_proxy.env docker compose up
```

For example, if `Z_WT_PROXY_PROXY_PORT_1=3000`, each worktree gets its own `Z_WT_PROXY_WORKTREE_PORT_1`.
The proxy daemon listens on the proxy port and forwards requests to the active worktree port.

## Concepts

- proxy port
  - stable port exposed on localhost
  - configured as `Z_WT_PROXY_PROXY_PORT_N`
- worktree port
  - allocated port for each git worktree
  - exposed to commands as `Z_WT_PROXY_WORKTREE_PORT_N`
- compose project name
  - generated per worktree
  - exposed as `COMPOSE_PROJECT_NAME`

## Workflow

```zsh
z.wt_proxy.init
z.wt_proxy.start
z.wt_proxy.env docker compose up
```

Use `z.wt_proxy.use` when switching the active worktree.

```zsh
cd /path/to/another/worktree
z.wt_proxy.use
```

## Commands

### init

- `z.wt_proxy.init`
  - create the project configuration file

Arguments:

- `proxy_port_N=<port>`
  - configure a stable proxy port
  - `N` is a port index such as `1`, `2`, or `3`
- `force=true`
  - overwrite the existing configuration file

```zsh
z.wt_proxy.init
z.wt_proxy.init proxy_port_1=3000 proxy_port_2=5432
z.wt_proxy.init proxy_port_4=8080 force=true
```

### env

- `z.wt_proxy.env`
  - print Docker Compose environment assignments
- `z.wt_proxy.env <command>`
  - run a command with Docker Compose environment values

Arguments:

- `<command>...`
  - command to run with `COMPOSE_PROJECT_NAME` and `Z_WT_PROXY_WORKTREE_PORT_N`
  - if omitted, `z.wt_proxy.env` prints the environment assignments

```zsh
z.wt_proxy.env
z.wt_proxy.env docker compose up
```

### use

- `z.wt_proxy.use`
  - activate the current worktree and print its proxy entry

```zsh
z.wt_proxy.use
```

### start

- `z.wt_proxy.start`
  - activate the current worktree and start the proxy daemon

```zsh
z.wt_proxy.start
```

### status

- `z.wt_proxy.status`
  - show the active entry and proxy daemon status

```zsh
z.wt_proxy.status
```

### stop

- `z.wt_proxy.stop`
  - stop the proxy daemon

```zsh
z.wt_proxy.stop
```

### rm

- `z.wt_proxy.rm`
  - remove the current worktree entry and its Docker images and volumes

```zsh
z.wt_proxy.rm
```

### prune

- `z.wt_proxy.prune`
  - remove stale worktree entries and their Docker images and volumes

```zsh
z.wt_proxy.prune
```

## Environment

Default proxy ports:

| key | environment variable | default |
| --- | --- | --- |
| `proxy_port_1` | `Z_WT_PROXY_PROXY_PORT_1` | `3000` |
| `proxy_port_2` | `Z_WT_PROXY_PROXY_PORT_2` | `5432` |
| `proxy_port_3` | `Z_WT_PROXY_PROXY_PORT_3` | `5173` |

```zsh
Z_WT_PROXY_PROXY_PORT_1=3000
Z_WT_PROXY_WORKTREE_PORT_1=13000
COMPOSE_PROJECT_NAME=project_branch_hash
```

In `docker-compose.yml`, use the worktree port values.

```yaml
services:
  app:
    ports:
      - "${Z_WT_PROXY_WORKTREE_PORT_1}:3000"
```

## Files

- config: `${XDG_CONFIG_HOME:-$HOME/.config}/worktree-proxy/<project>.env`
- state: `${XDG_STATE_HOME:-$HOME/.local/state}/worktree-proxy/<project>.state`
- lock: `${XDG_STATE_HOME:-$HOME/.local/state}/worktree-proxy/<project>.lock`
- pid: `${XDG_STATE_HOME:-$HOME/.local/state}/worktree-proxy/<project>.pid`
- log: `${XDG_STATE_HOME:-$HOME/.local/state}/worktree-proxy/<project>.log`
