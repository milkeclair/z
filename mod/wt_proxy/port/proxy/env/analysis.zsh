# get the environment variable name from the proxy port key
#
# $1: proxy port key
# REPLY: environment variable name
# return: null
#
# example:
#  z.wt_proxy._port.proxy.env.key proxy_port_1
z.wt_proxy._port.proxy.env.key() {
  local key=$1

  z.wt_proxy._port.proxy.index $key || { z.return; return; }
  local port_index=$REPLY

  z.return "$z_wt_proxy_proxy_port_env_prefix$port_index"
}

# get the index from the proxy port environment variable name
#
# $1: environment variable name
# REPLY: port index|null
# return: 0 if the name is a numbered proxy port environment variable, otherwise 1
#
# example:
#  z.wt_proxy._port.proxy.env.index Z_WT_PROXY_PROXY_PORT_1
z.wt_proxy._port.proxy.env.index() {
  local env_name=$1

  if [[ $env_name == ${z_wt_proxy_proxy_port_env_prefix}<-> ]]; then
    z.return ${env_name#$z_wt_proxy_proxy_port_env_prefix}
    return
  fi

  z.return
  return 1
}
