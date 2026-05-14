# get a public port environment name for a configuration key
#
# $1: configuration key
# REPLY: environment variable name
# return: null
#
# example:
#  z.wt_proxy._port.public.env.key public_port_1
z.wt_proxy._port.public.env.key() {
  local key=$1

  z.wt_proxy._port.public.config.index $key || { z.return; return; }
  local port_index=$REPLY

  z.return "$z_wt_proxy_public_port_env_prefix$port_index"
}

# get a port index from a public port environment name
#
# $1: environment variable name
# REPLY: port index|null
# return: 0 if the name is a numbered public port env, otherwise 1
#
# example:
#  z.wt_proxy._port.public.env.index Z_WT_PROXY_PUBLIC_PORT_1
z.wt_proxy._port.public.env.index() {
  local env_name=$1

  if [[ $env_name == ${z_wt_proxy_public_port_env_prefix}<-> ]]; then
    z.return ${env_name#$z_wt_proxy_public_port_env_prefix}
    return
  fi

  z.return
  return 1
}
