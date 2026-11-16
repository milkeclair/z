# 環境変数からwtproxyの設定値を取得する
#
# REPLY: 設定のキーと値の組
# return: null
#
# example:
#  # 他のZ_WTPROXY_PROXY_PORT_Nは未設定の場合
#  local Z_WTPROXY_PROXY_PORT_1=3000
#  z.wtproxy._config.port.env.values
#  # REPLY: ("proxy_port_1" "3000")
z.wtproxy._config.port.env.values() {
  zmodload zsh/parameter

  local -A config=()

  z.hash.keys parameters
  for env_name in ${(@)REPLY}; do
    z.wtproxy._config.file.key $env_name || continue
    local key=$REPLY

    z.wtproxy._port.proxy.env $key
    local value=$REPLY
    z.is.not.null "$value" && config[$key]=$value
  done

  z.hash.entries config
}
