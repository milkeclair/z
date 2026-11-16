# z.wtproxy

複数のGit worktreeで、ポートを競合させずDocker Composeプロジェクトを動かすmodです。

## インストール

`z.install.mod wtproxy`

`git`がなければ同時に導入します。

## 概要

worktreeごとに独立したポート値でDocker Composeを実行できます。

```zsh
z.wtproxy.init
z.wtproxy.start
z.wtproxy.env docker compose up
```

例えば`Z_WTPROXY_PROXY_PORT_1=3000`なら、各worktreeへ固有の`Z_WTPROXY_WORKTREE_PORT_1`を割り当てます。プロキシデーモンはプロキシポートで待ち受け、有効なworktreeのポートへ要求を転送します。

## 用語

- プロキシポート
  - localhostに公開する固定ポート
  - `Z_WTPROXY_PROXY_PORT_N`で設定します。
- worktreeポート
  - Git worktreeごとに割り当てるポート
  - コマンドには`Z_WTPROXY_WORKTREE_PORT_N`として渡します。
- Composeプロジェクト名
  - worktreeごとに生成します。
  - `COMPOSE_PROJECT_NAME`として渡します。

## 処理の流れ

```zsh
z.wtproxy.init
z.wtproxy.start
z.wtproxy.env docker compose up
```

有効なworktreeを切り替えるには`z.wtproxy.use`を使います。

```zsh
cd /path/to/another/worktree
z.wtproxy.use
```

## コマンド

### init

- `z.wtproxy.init`
  - プロジェクトの設定ファイルを作成します。

引数:

- `proxy_port_N=<port>`
  - 固定のプロキシポートを設定します。
  - `N`は`1`・`2`・`3`などのポートのインデックスです。
- `force=true`
  - 既存の設定ファイルを上書きします。

```zsh
z.wtproxy.init
z.wtproxy.init proxy_port_1=3000 proxy_port_2=5432
z.wtproxy.init proxy_port_4=8080 force=true
```

### env

- `z.wtproxy.env`
  - Docker Composeの環境変数の代入式を表示します。
- `z.wtproxy.env <command>`
  - Docker Composeの環境変数を渡してコマンドを実行します。

引数:

- `<command>...`
  - `COMPOSE_PROJECT_NAME`と`Z_WTPROXY_WORKTREE_PORT_N`を渡して実行するコマンド
  - 省略すると`z.wtproxy.env`は環境変数の代入式を表示します。

```zsh
z.wtproxy.env
z.wtproxy.env docker compose up
```

### use

- `z.wtproxy.use`
  - 現在のworktreeを有効にし、そのプロキシエントリを表示します。

```zsh
z.wtproxy.use
```

### start

- `z.wtproxy.start`
  - 現在のworktreeを有効にし、プロキシデーモンを起動します。

```zsh
z.wtproxy.start
```

### status

- `z.wtproxy.status`
  - 有効なエントリとプロキシデーモンの状態を表示します。

```zsh
z.wtproxy.status
```

### stop

- `z.wtproxy.stop`
  - プロキシデーモンを停止します。

```zsh
z.wtproxy.stop
```

### rm

- `z.wtproxy.rm`
  - 現在のworktreeエントリと、そのDockerイメージ・ボリュームを削除します。

```zsh
z.wtproxy.rm
```

### prune

- `z.wtproxy.prune`
  - 古いworktreeエントリと、そのDockerイメージ・ボリュームを削除します。

```zsh
z.wtproxy.prune
```

## 環境変数

プロキシポートの既定値:

| キー | 環境変数 | 既定値 |
| --- | --- | --- |
| `proxy_port_1` | `Z_WTPROXY_PROXY_PORT_1` | `3000` |
| `proxy_port_2` | `Z_WTPROXY_PROXY_PORT_2` | `5432` |
| `proxy_port_3` | `Z_WTPROXY_PROXY_PORT_3` | `5173` |

```zsh
Z_WTPROXY_PROXY_PORT_1=3000
Z_WTPROXY_WORKTREE_PORT_1=13000
COMPOSE_PROJECT_NAME=project_branch_hash
```

`docker-compose.yml`ではworktreeポートの値を使います。

```yaml
services:
  app:
    ports:
      - "${Z_WTPROXY_WORKTREE_PORT_1}:3000"
```

## ファイル

- 設定: `${XDG_CONFIG_HOME:-$HOME/.config}/wtproxy/<project>.env`
- 状態: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.state`
- ロック: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.lock`
- PID: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.pid`
- ログ: `${XDG_STATE_HOME:-$HOME/.local/state}/wtproxy/<project>.log`
