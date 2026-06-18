# get a wtproxy configuration value for the initial file
#
# $1: configuration key
# $@: named configuration values
# REPLY: configuration value|null
# return: null
#
# example:
#  z.wtproxy.init._config.port.value proxy_port_1 proxy_port_1=3000
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

  z.return "$value"
}

# get configuration keys for the initial file
#
# $@: named configuration values
# REPLY: configuration keys
# return: null
#
# example:
#  z.wtproxy.init._config.port.keys proxy_port_4=8080
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

  z.return ${result[@]}
}
