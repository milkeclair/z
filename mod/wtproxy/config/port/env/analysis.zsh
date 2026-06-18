# get wtproxy configuration values from environment variables
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wtproxy._config.port.env.values
z.wtproxy._config.port.env.values() {
  zmodload zsh/parameter

  local -A config=()

  for env_name in ${(k)parameters}; do
    z.wtproxy._config.file.key $env_name || continue
    local key=$REPLY

    z.wtproxy._port.proxy.env $key
    local value=$REPLY
    z.is.not.null "$value" && config[$key]=$value
  done

  z.return.hash config
}
