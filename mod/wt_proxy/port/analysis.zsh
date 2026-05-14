# get a port key for an index
#
# $1: port index
# REPLY: port key
# return: null
#
# example:
#  z.wt_proxy._port.key 1
z.wt_proxy._port.key() {
  local port_index=$1

  z.return "$z_wt_proxy_port_key_prefix$port_index"
}

# get a port index from a port key
#
# $1: port key
# REPLY: port index|null
# return: 0 if the key is a numbered port key, otherwise 1
#
# example:
#  z.wt_proxy._port.index port_1
z.wt_proxy._port.index() {
  local key=$1

  if [[ $key == ${z_wt_proxy_port_key_prefix}<-> ]]; then
    z.return ${key#$z_wt_proxy_port_key_prefix}
    return
  fi

  z.return
  return 1
}

# get port keys from configuration
#
# REPLY: numbered port keys
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wt_proxy._port.keys
z.wt_proxy._port.keys() {
  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")

  z.wt_proxy._port.keys.from_config config
}

# get public proxy ports from configuration
#
# REPLY: public ports
# return: 0 if configuration is available, otherwise 1
#
# example:
#  z.wt_proxy._port.publics
z.wt_proxy._port.publics() {
  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")
  local ports=()

  z.wt_proxy._port.keys.from_config config
  for port_key in ${(@)REPLY}; do
    z.wt_proxy._port.index $port_key || return 1
    local port_index=$REPLY
    z.wt_proxy._port.public.config.key $port_index
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
#  z.wt_proxy._port.used
z.wt_proxy._port.used() {
  local ports=()

  for state_key in ${(k)z_wt_proxy_state_port}; do
    z.is.not.null $z_wt_proxy_state_port[$state_key] && ports+=($z_wt_proxy_state_port[$state_key])
  done

  z.return ${ports[@]}
}

# get public port for a port key
#
# $1: port key
# REPLY: public port
# return: 0 if key is known, otherwise 1
#
# example:
#  z.wt_proxy._port.public port_1
z.wt_proxy._port.public() {
  local port_key=$1

  z.wt_proxy._config || return 1
  local -A config=("${(@)REPLY}")
  z.wt_proxy._port.index $port_key || {
    z.io.error "Unknown port key: $port_key"
    return 1
  }

  local port_index=$REPLY
  z.wt_proxy._port.public.config.key $port_index
  local config_key=$REPLY

  if z.is.null $config[$config_key]; then
    z.io.error "Unknown port key: $port_key"
    return 1
  fi

  z.return $config[$config_key]
}
