# 初期ファイル用のwtproxy設定値を取得する
#
# $1: 設定キー
# $@: 名前付きの設定値
# REPLY: 設定値|null
# return: null
#
# example:
#  z.wtproxy.init._config.port.value proxy_port_1 proxy_port_1=3000
#  # REPLY: "3000"
z.wtproxy.init._config.port.value() {
  local key=$1 && shift
  z.arg.named $key $@
  local value=$REPLY

  if z.is.null "$value"; then
    z.wtproxy._port.proxy.env $key
    value=$REPLY
  fi

  if z.is.null "$value"; then
    value=$z_wtproxy_default_config_values[$key]
  fi

  REPLY="$value"
}

# 初期ファイル用の設定キーを取得する
#
# $@: 名前付きの設定値
# REPLY: 設定キーの一覧
# return: null
#
# example:
#  # 既定の3ポート以外に環境変数の追加指定がない場合
#  z.wtproxy.init._config.port.keys proxy_port_4=8080
#  # REPLY: ("proxy_port_1" "proxy_port_2" "proxy_port_3" "proxy_port_4")
z.wtproxy.init._config.port.keys() {
  z.group "default values"; {
    z.hash.keys z_wtproxy_default_config_values
    local -a keys=("${(@)REPLY}")
  }

  z.group "from provided keys"; {
    for arg in "$@"; do
      z.str.split str="$arg" delimiter="="
      local key=$REPLY[1]
      z.wtproxy._port.proxy.index $key || continue
      keys+=($key)
    done
  }

  z.group "environment proxy config"; {
    z.wtproxy._config.port.env.values
    local -A env_config=("${(@)REPLY}")
    z.hash.keys env_config
    keys+=("${(@)REPLY}")
  }

  z.arr.unique ${keys[@]}
  local -a unique_keys=("${(@)REPLY}")
  local -A key_config=()

  for key in $unique_keys; do
    key_config[$key]=true
  done

  z.wtproxy._port.keys.from_config key_config
  local -a port_keys=("${(@)REPLY}")
  local -a result=()

  for port_key in $port_keys; do
    z.wtproxy._port.worktree.index $port_key
    local port_index=$REPLY
    z.wtproxy._port.proxy.key $port_index
    result+=($REPLY)
  done

  REPLY=("${result[@]}")
}
