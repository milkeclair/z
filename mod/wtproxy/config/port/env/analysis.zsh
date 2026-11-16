# 環境変数からwtproxyの設定値を取得する
#
# REPLY: 設定のキーと値の組
# return: null
#
# example:
#  z.wtproxy._config.port.env.values
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
