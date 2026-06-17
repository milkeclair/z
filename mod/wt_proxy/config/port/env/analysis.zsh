# get wt_proxy configuration values from environment variables
#
# REPLY: configuration hash as key-value pairs
# return: null
#
# example:
#  z.wt_proxy._config.port.env.values
z.wt_proxy._config.port.env.values() {
  zmodload zsh/parameter

  local -A config=()

  for env_name in ${(k)parameters}; do
    z.wt_proxy._config.file.key $env_name || continue
    local key=$REPLY

    z.wt_proxy._port.proxy.env $key
    local value=$REPLY
    z.is.not.null "$value" && config[$key]=$value
  done

  z.return.hash config
}
