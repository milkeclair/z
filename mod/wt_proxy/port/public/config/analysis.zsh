# get a public port configuration key for an index
#
# $1: port index
# REPLY: configuration key
# return: null
#
# example:
#  z.wt_proxy._port.public.config.key 1
z.wt_proxy._port.public.config.key() {
  local port_index=$1

  z.return "$z_wt_proxy_public_port_config_prefix$port_index"
}

# get a port index from a public port configuration key
#
# $1: configuration key
# REPLY: port index|null
# return: 0 if the key is a numbered public port key, otherwise 1
#
# example:
#  z.wt_proxy._port.public.config.index public_port_1
z.wt_proxy._port.public.config.index() {
  local key=$1

  if [[ $key == ${z_wt_proxy_public_port_config_prefix}<-> ]]; then
    z.return ${key#$z_wt_proxy_public_port_config_prefix}
    return
  fi

  z.return
  return 1
}
