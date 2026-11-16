# wtproxyの設定を取得する
#
# REPLY: 設定のキーと値の組
# return: null
#
# example:
#  # Gitプロジェクト名がsample、XDG_STATE_HOME=/tmp/stateの場合
#  z.wtproxy._config
#  local -A config=($REPLY)
#  # config[project]: "sample"
#  # config[state_file]: "/tmp/state/wtproxy/sample.state"
#  # config[host]: "127.0.0.1"
z.wtproxy._config() {
  z.wtproxy._config.values
  local -A config=("${(@)REPLY}")

  z.wtproxy._config.file.default_project || {
    z.io.error "git worktree root is required"
    return 1
  }
  config[project]=$REPLY

  local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/$z_wtproxy_state_dir_name"

  config[host]=$z_wtproxy_host
  config[state_dir]=$state_dir
  config[state_file]="$state_dir/$config[project].state"
  config[lock_file]="$state_dir/$config[project].lock"
  config[pid_file]="$state_dir/$config[project].pid"
  config[log_file]="$state_dir/$config[project].log"

  z.hash.entries config
}

# wtproxyの設定値を1つ取得する
#
# $1: 設定キー
# REPLY: 設定値
# return: 設定を取得できた場合は0、それ以外は1
#
# example:
#  # Gitプロジェクト名がsample、XDG_STATE_HOME=/tmp/stateの場合
#  z.wtproxy._config.value state_file
#  # REPLY: "/tmp/state/wtproxy/sample.state"
#  # return: 0
z.wtproxy._config.value() {
  local config_key=$1

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  REPLY="${config[$config_key]}"
}

# 既定値・ファイル設定・環境変数からwtproxyの設定値を取得する
#
# REPLY: 設定のキーと値の組
# return: null
#
# example:
#  # ファイル・環境変数による上書きがない場合
#  z.wtproxy._config.values
#  local -A config=($REPLY)
#  # config: proxy_port_1=3000、proxy_port_2=5432、proxy_port_3=5173
z.wtproxy._config.values() {
  local -A config=("${(@kv)z_wtproxy_default_config_values}")

  z.wtproxy._config.file.values
  local -A file_config=("${(@)REPLY}")

  z.hash.merge base=config other=file_config
  config=("${(@)REPLY}")

  # envがconfig fileより優先
  z.wtproxy._config.port.env.values
  local -A env_config=("${(@)REPLY}")

  z.hash.merge base=config other=env_config
  config=("${(@)REPLY}")

  z.hash.entries config
}
