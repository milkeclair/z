# get worktree port keys from configuration
#
# REPLY: numbered worktree port keys
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wtproxy._port.keys
z.wtproxy._port.keys() {
  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.wtproxy._port.keys.from_config config
}

# get proxy ports from configuration
#
# REPLY: proxy port
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wtproxy._port.proxies
z.wtproxy._port.proxies() {
  z.wtproxy._config || return 1
  local -A config=("${(@)REPLY}")
  local ports=()

  z.wtproxy._port.keys.from_config config
  for port_key in ${(@)REPLY}; do
    z.wtproxy._port.worktree.index $port_key || return 1
    local port_index=$REPLY
    z.wtproxy._port.proxy.key $port_index
    local config_key=$REPLY
    ports+=($config[$config_key])
  done

  z.return ${ports[@]}
}

# get ports already assigned in state
#
# REPLY: assigned ports
# return: null
#
# example:
#  z.wtproxy._port.used
z.wtproxy._port.used() {
  local ports=()

  for state_key in ${(k)z_wtproxy_state_port}; do
    z.is.not.null $z_wtproxy_state_port[$state_key] && ports+=($z_wtproxy_state_port[$state_key])
  done

  z.return ${ports[@]}
}

# get the proxy port for a worktree port key
#
# $1: worktree port key
# REPLY: proxy port
# return: 0 if key exists, otherwise 1
#
# example:
#  z.wtproxy._port.proxy worktree_port_1
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

  z.return $config[$config_key]
}
