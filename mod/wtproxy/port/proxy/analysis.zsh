# get the proxy port key from the index
#
# $1: port index
# REPLY: proxy port key
# return: null
#
# example:
#  z.wtproxy._port.proxy.key 1
z.wtproxy._port.proxy.key() {
  local port_index=$1

  z.return "$z_wtproxy_proxy_port_key_prefix$port_index"
}

# get the index from the proxy port key
#
# $1: proxy port key
# REPLY: port index|null
# return: 0 if for numbered proxy port keys, otherwise 1
#
# example:
#  z.wtproxy._port.proxy.index proxy_port_1
z.wtproxy._port.proxy.index() {
  local key=$1

  if [[ $key == ${z_wtproxy_proxy_port_key_prefix}<-> ]]; then
    z.return ${key#$z_wtproxy_proxy_port_key_prefix}
    return
  fi

  z.return
  return 1
}

# get the environment variable value for a proxy port
#
# $1: proxy port key
# REPLY: environment variable value
# return: null
#
# example:
#  z.wtproxy._port.proxy.env proxy_port_1
z.wtproxy._port.proxy.env() {
  local key=$1

  z.wtproxy._port.proxy.env.key $key
  z.var.get $REPLY
}
