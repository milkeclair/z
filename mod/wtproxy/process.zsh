# wtproxyの状態を表示する
#
# REPLY: null
# return: null
#
# example:
#  # 有効な設定があり、activeなし・プロキシ停止中の場合
#  z.wtproxy
#  # 出力:
#  # active: none
#  # proxy: stopped
z.wtproxy() {
  z.wtproxy.status
}

# wtproxyのヘルプを表示する
#
# REPLY: null
# return: null
#
# example:
#  z.wtproxy.help
#  # 表示例（一部、余白を省略）: init: z.wtproxy.init ?proxy_port_N=<port> ?force=true
z.wtproxy.help() {
  z.io.empty
  z.io indent=1 "Usage:"
  z.io indent=2 "init:    z.wtproxy.init ?proxy_port_N=<port> ?force=true"
  z.io indent=3 "create the config file"
  z.io indent=2 "env:     z.wtproxy.env ?command..."
  z.io indent=3 "print env assignments or run command with them"
  z.io indent=2 "use:     z.wtproxy.use"
  z.io indent=3 "activate the current worktree"
  z.io indent=2 "start:   z.wtproxy.start"
  z.io indent=3 "activate the current worktree and start the proxy daemon"
  z.io indent=2 "status:  z.wtproxy.status"
  z.io indent=3 "show active entry and proxy daemon status"
  z.io indent=2 "stop:    z.wtproxy.stop"
  z.io indent=3 "stop the proxy daemon"
  z.io indent=2 "rm:      z.wtproxy.rm"
  z.io indent=3 "remove the current entry and its Docker resources"
  z.io indent=2 "prune:   z.wtproxy.prune"
  z.io indent=3 "remove stale entries and their Docker resources"
  z.io.line
  z.io indent=1 "Workflow:"
  z.io indent=2 "1. z.wtproxy.init"
  z.io indent=2 "2. z.wtproxy.use or z.wtproxy.start"
  z.io indent=2 "3. z.wtproxy.env docker compose up"
  z.io.line
  z.io indent=1 "Notes:"
  z.io indent=2 "rm/prune remove Docker images and volumes for the stored compose project."
  z.io.line
  z.io indent=1 "Environment:"
  z.io indent=2 "proxy:   Z_WTPROXY_PROXY_PORT_N"
  z.io indent=2 "worktree: Z_WTPROXY_WORKTREE_PORT_N"
  z.io indent=2 "compose: COMPOSE_PROJECT_NAME"
  z.io.line
  z.io indent=1 "Files:"
  z.io indent=2 "config:  \${XDG_CONFIG_HOME:-\$HOME/.config}/wtproxy/<project>.env"
  z.io indent=2 "state:   \${XDG_STATE_HOME:-\$HOME/.local/state}/wtproxy/<project>.state"
}

# wtproxyの初期設定ファイルを作成する
#
# $@: 名前付きの設定値
# REPLY: null
# return: ファイルを作成できた場合は0、それ以外は1
#
# example:
#  # 有効なGitプロジェクトで、設定ファイルが未作成の場合
#  z.wtproxy.init proxy_port_1=3000
#  # return: 0
#  # 保存される行の例: Z_WTPROXY_PROXY_PORT_1=3000
z.wtproxy.init() {
  z.wtproxy.init._config.file "$@"
}

# Docker Composeの環境変数を表示するか、その環境でコマンドを実行する
#
# $@?: 環境変数を渡して実行するコマンド
# REPLY: null
# return: コマンド指定時はその終了コード、表示した場合は0、それ以外は1
#
# example:
#  # Compose名がsample_feat_example_b671591e、worktreeポートが3001の場合
#  z.wtproxy.env sh -c 'printf "%s\n" "$COMPOSE_PROJECT_NAME"'
#  # 出力: sample_feat_example_b671591e
#  # return: 0
z.wtproxy.env() {
  z.wtproxy._entry.current || return 1
  local -A entry=("${(@)REPLY}")
  local -a env_values=(
    "COMPOSE_PROJECT_NAME=$entry[compose_project_name]"
  )

  z.wtproxy._port.keys || return 1
  for port_key in ${(@)REPLY}; do
    z.wtproxy._port.worktree.index $port_key
    local port_index=$REPLY
    env_values+=("$z_wtproxy_worktree_port_env_prefix$port_index=$entry[$port_key]")
  done

  z.arr.count "$@"
  if z.int.is.gt $REPLY 0; then
    (
      export "${env_values[@]}"
      "$@"
    )
    return $?
  fi

  z.io.line ${env_values[@]}
}

# 現在のworktreeを有効にし、そのプロキシエントリを表示する
#
# REPLY: null
# return: 現在のエントリを取得できた場合は0、それ以外は1
#
# example:
#  # 現在のworktreeが/tmp/worktreeで、有効な設定を取得できる場合
#  z.wtproxy.use
#  # return: 0
#  # 保存後のactive: "/tmp/worktree"
#  # 表示例（一部）: path: /tmp/worktree
z.wtproxy.use() {
  z.wtproxy._entry.current activate=true || return 1
  z.wtproxy._print.entry "${(@)REPLY}"
}

# 現在のworktreeを有効にし、プロキシデーモンを起動する
#
# REPLY: null
# return: プロキシを起動できた場合は0、それ以外は1
#
# example:
#  # 待受ポートが空いており、プロキシを起動できる場合
#  z.wtproxy.start
#  # return: 0
#  # 結果: 現在のworktreeが有効になり、プロキシが待受を開始する
z.wtproxy.start() {
  z.wtproxy._entry.current activate=true || return 1
  local -A entry=("${(@)REPLY}")
  z.wtproxy.start._daemon || return 1
  z.wtproxy._print.entry "${(@kv)entry}"
}

# プロキシデーモンを停止する
#
# REPLY: null
# return: null
#
# example:
#  # プロキシが動作中で、停止に成功した場合
#  z.wtproxy.stop
#  # 出力: stopped
z.wtproxy.stop() {
  if z.wtproxy.stop._daemon; then
    z.io "stopped"
  else
    z.io "not running"
  fi
}

# 有効なエントリとプロキシデーモンの状態を表示する
#
# REPLY: null
# return: null
#
# example:
#  # 有効な設定があり、activeなし・プロキシ停止中の場合
#  z.wtproxy.status
#  # 出力:
#  # active: none
#  # proxy: stopped
z.wtproxy.status() {
  if z.wtproxy._entry.active; then
    z.wtproxy._print.entry "${(@)REPLY}"
  else
    z.io "active: none"
  fi

  if z.wtproxy._proxy.is.running; then
    z.io "proxy: running"
  else
    z.io "proxy: stopped"
  fi
}

# 現在のworktreeエントリとそのDockerリソースを削除する
#
# REPLY: null
# return: 現在のエントリを削除できた場合は0、それ以外は1
#
# example:
#  # /tmp/worktreeが唯一のエントリで、Dockerリソースの削除と保存が成功する場合
#  z.wtproxy.rm
#  # return: 0
#  # 出力:
#  # removed: /tmp/worktree
#  # entries: 0
#  # docker_resource_project: sample_feat_example_b671591e
z.wtproxy.rm() {
  z.wtproxy.rm._current.entry || return 1
  local -A entry=("${(@)REPLY}")

  local project_name=$entry[compose_project_name]
  if z.is.not.null "$project_name"; then
    z.wtproxy._docker.prune "$project_name" || return 1
  fi

  z.wtproxy.rm._current expected_project="$project_name" || return 1
  local -A result=("${(@)REPLY}")

  z.io "removed: $result[removed_path]"
  z.io "entries: $result[entries_count]"
  if z.is.not.null "$result[removed_project]"; then
    z.io "docker_resource_project: $result[removed_project]"
  fi
}

# 状態から古いworktreeエントリを取り除く
#
# REPLY: null
# return: 状態を更新できた場合は0、それ以外は1
#
# example:
#  # 不存在のworktreeが1件だけあり、そのComposeリソースも削除できる場合
#  z.wtproxy.prune
#  # return: 0
#  # 出力:
#  # entries: 0
#  # docker_resource_projects: sample_feat_example_b671591e
z.wtproxy.prune() {
  z.wtproxy.prune._stale || return 1
  local -A result=("${(@)REPLY}")

  z.io "entries: $result[entries_count]"
  if z.is.not.null "$result[pruned_projects]"; then
    z.io "docker_resource_projects: $result[pruned_projects]"
  fi
}
