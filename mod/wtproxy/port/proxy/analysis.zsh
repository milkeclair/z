# インデックスからプロキシポートキーを取得する
#
# $1: ポートのインデックス
# REPLY: プロキシポートキー
# return: null
#
# example:
#  z.wtproxy._port.proxy.key 1
z.wtproxy._port.proxy.key() {
  local port_index=$1

  REPLY="$z_wtproxy_proxy_port_key_prefix$port_index"
}

# プロキシポートキーからインデックスを取得する
#
# $1: プロキシポートキー
# REPLY: ポートのインデックス|null
# return: 連番のプロキシポートキーの場合は0、それ以外は1
#
# example:
#  z.wtproxy._port.proxy.index proxy_port_1
z.wtproxy._port.proxy.index() {
  local key=$1

  if z.str.is.match "$key" "^${z_wtproxy_proxy_port_key_prefix}[0-9]+$"; then
    z.str.remove.prefix "$key" "$z_wtproxy_proxy_port_key_prefix"
    return 0
  fi

  REPLY=""
  return 1
}

# プロキシポートに対応する環境変数の値を取得する
#
# $1: プロキシポートキー
# REPLY: 環境変数の値
# return: null
#
# example:
#  z.wtproxy._port.proxy.env proxy_port_1
z.wtproxy._port.proxy.env() {
  local key=$1

  z.wtproxy._port.proxy.env.key $key
  z.var.get $REPLY
}
