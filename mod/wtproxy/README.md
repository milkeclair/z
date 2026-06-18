# z.wtproxy

A modifier for running Docker Compose projects from multiple git worktrees without port conflicts.

## Installation

`z.install.mod wtproxy`

This also installs `git` when it is missing.

## Overview

Each worktree can run Docker Compose with its own port values.

```zsh
z.wtproxy.init
z.wtproxy.start
z.wtproxy.env docker compose up
```

For example, if `Z_WTPROXY_PROXY_PORT_1=3000`, each worktree gets its own `Z_WTPROXY_WORKTREE_PORT_1`.
The proxy daemon listens on the proxy port and forwards requests to the active worktree port.

## Concepts

- proxy port
  - stable port exposed on localhost
  - configured as `Z_WTPROXY_PROXY_PORT_N`
- worktree port
  - allocated port for each git worktree
  - exposed to commands as `Z_WTPROXY_WORKTREE_PORT_N`
- compose project name
  - generated per worktree
  - exposed as `COMPOSE_PROJECT_NAME`

## Workflow

```zsh
z.wtproxy.init
z.wtproxy.start
z.wtproxy.env docker compose up
```

Use `z.wtproxy.use` when switching the active worktree.

```zsh
cd /path/to/another/worktree
z.wtproxy.use
```

## Commands

### init

- `z.wtproxy.init`
  - create the project configuration file

Arguments:

- `proxy_port_N=<port>`
  - configure a stable proxy port
  - `N` is a port index such as `1`, `2`, or `3`
- `force=true`
  - overwrite the existing configuration file

```zsh
z.wtproxy.init
z.wtproxy.init proxy_port_1=3000 proxy_port_2=5432
z.wtproxy.init proxy_port_4=8080 force=true
```

### env

- `z.wtproxy.env`
  - print Docker Compose environment assignments
- `z.wtproxy.env <command>`
  - run a command with Docker Compose environment values

Arguments:

- `<command>...`
  - command to run with `COMPOSE_PROJECT_NAME` and `Z_WTPROXY_WORKTREE_PORT_N`
  - if omitted, `z.wtproxy.env` prints the environment assignments

```zsh
z.wtproxy.env
z.wtproxy.env docker compose up
```

### use

- `z.wtproxy.use`
  - activate the current worktree and print its proxy entry

```zsh
z.wtproxy.use
```

### start

- `z.wtproxy.start`
  - activate the current worktree and start the proxy daemon

```zsh
z.wtproxy.start
```

### status

- `z.wtproxy.status`
  - show the active entry and proxy daemon status

```zsh
z.wtproxy.status
```

### stop

- `z.wtproxy.stop`
  - stop the proxy daemon

```zsh
z.wtproxy.stop
```

### rm

- `z.wtproxy.rm`
  - remove the current worktree entry and its Docker images and volumes

```zsh
z.wtproxy.rm
```

### prune

- `z.wtproxy.prune`
  - remove stale worktree entries and their Docker images and volumes

```zsh
z.wtproxy.prune
```

## Environment

Default proxy ports:

| key | environment variable | default |
| --- | --- | --- |
| `proxy_port_1` | `Z_WTPROXY_PROXY_PORT_1` | `3000` |
| `proxy_port_2` | `Z_WTPROXY_PROXY_PORT_2` | `5432` |
| `proxy_port_3` | `Z_WTPROXY_PROXY_PORT_3` | `5173` |

```zsh
Z_WTPROXY_PROXY_PORT_1=3000
Z_WTPROXY_WORKTREE_PORT_1=13000
COMPOSE_PROJECT_NAME=project_branch_hash
```

In `docker-compose.yml`, use the worktree port values.

```yaml
services:
  app:
    ports:
      - "${Z_WTPROXY_WORKTREE_PORT_1}:3000"
```

## Files

- config: `${XDG_CONFIG_HOME:-$HOME/.config}/wtproxy/<project>.env`
- state: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.state`
- lock: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.lock`
- pid: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.pid`
- log: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.log`
