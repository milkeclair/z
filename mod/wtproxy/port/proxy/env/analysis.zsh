# プロキシポートキーに対応する環境変数名を取得する
#
# $1: プロキシポートキー
# REPLY: 環境変数名
# return: null
#
# example:
#  z.wtproxy._port.proxy.env.key proxy_port_1
#  # REPLY: "Z_WTPROXY_PROXY_PORT_1"
z.wtproxy._port.proxy.env.key() {
  local key=$1

  z.wtproxy._port.proxy.index $key || { REPLY=""; return; }
  local port_index=$REPLY

  REPLY="$z_wtproxy_proxy_port_env_prefix$port_index"
}

# プロキシポート環境変数名からインデックスを取得する
#
# $1: 環境変数名
# REPLY: ポートのインデックス|null
# return: 連番のプロキシポート環境変数名の場合は0、それ以外は1
#
# example:
#  z.wtproxy._port.proxy.env.index Z_WTPROXY_PROXY_PORT_1
#  # REPLY: "1"
#  # return: 0
z.wtproxy._port.proxy.env.index() {
  local env_name=$1

  if z.str.is.match "$env_name" "^${z_wtproxy_proxy_port_env_prefix}[0-9]+$"; then
    z.str.remove.prefix "$env_name" "$z_wtproxy_proxy_port_env_prefix"
    return 0
  fi

  REPLY=""
  return 1
}
