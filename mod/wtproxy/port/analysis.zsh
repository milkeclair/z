# 設定からworktreeポートキーを取得する
#
# REPLY: 連番のworktreeポートキー
# return: 設定を取得できた場合は0、それ以外は1
#
# example:
#  # 既定の3ポートが有効な場合
#  z.wtproxy._port.keys
#  # REPLY: ("worktree_port_1" "worktree_port_2" "worktree_port_3")
#  # return: 0
z.wtproxy._port.keys() {
  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.wtproxy._port.keys.from_config config
}

# 設定からプロキシポートを取得する
#
# REPLY: プロキシポート
# return: 設定を取得できた場合は0、それ以外は1
#
# example:
#  # 既定の3ポートを使う場合
#  z.wtproxy._port.proxies
#  # REPLY: ("3000" "5432" "5173")
#  # return: 0
z.wtproxy._port.proxies() {
  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  local ports=()

  z.wtproxy._port.keys.from_config config
  for port_key in ${(@)REPLY}; do
    z.wtproxy._port.worktree.index $port_key
    local port_index=$REPLY
    z.wtproxy._port.proxy.key $port_index
    local config_key=$REPLY
    ports+=($config[$config_key])
  done

  REPLY=("${ports[@]}")
}

# 状態に割り当て済みのポートを取得する
#
# REPLY: 割り当て済みのポート
# return: null
#
# example:
#  z_wtproxy_state_port=("/tmp/worktree|worktree_port_1" 3001)
#  z.wtproxy._port.used
#  # REPLY: ("3001")
z.wtproxy._port.used() {
  local ports=()

  z.hash.keys z_wtproxy_state_port
  for state_key in ${(@)REPLY}; do
    z.is.not.null $z_wtproxy_state_port[$state_key] && ports+=($z_wtproxy_state_port[$state_key])
  done

  REPLY=("${ports[@]}")
}

# worktreeポートキーに対応するプロキシポートを取得する
#
# $1: worktreeポートキー
# REPLY: プロキシポート
# return: キーが存在する場合は0、それ以外は1
#
# example:
#  # proxy_port_1=3000の設定の場合
#  z.wtproxy._port.proxy worktree_port_1
#  # REPLY: "3000"
#  # return: 0
z.wtproxy._port.proxy() {
  local port_key=$1

  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.wtproxy._port.worktree.index $port_key || {
    z.io.error "Unknown port key: $port_key"
    return 1
  }

  local port_index=$REPLY
  z.wtproxy._port.proxy.key $port_index
  local config_key=$REPLY

  if z.is.null $config[$config_key]; then
    z.io.error "Unknown port key: $port_key"
    return 1
  fi

  REPLY=$config[$config_key]
}
