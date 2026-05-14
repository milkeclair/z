# allocate a worktree port for a port key
#
# $1: worktree path
# $2: port key
# REPLY: allocated port
# return: 0 if a port is allocated, otherwise 1
#
# example:
#  z.wt_proxy._port.allocate /path/to/worktree port_1
z.wt_proxy._port.allocate() {
  local worktree_path=$1
  local port_key=$2

  z.wt_proxy._port.public $port_key || return 1
  local base_port=$REPLY

  z.wt_proxy._port.used
  local used_ports=("${(@)REPLY}")
  z.wt_proxy._port.publics
  used_ports+=("${(@)REPLY}")

  for ((step=0; step<z_wt_proxy_port_range; step++)); do
    local port=$((base_port + step))

    z.wt_proxy._port.is.used $port ${used_ports[@]} && continue
    z.wt_proxy._port.is.free $port || continue

    z.return $port
    return
  done

  z.io.error "No available worktree port for $port_key"
  return 1
}
