# worktreeポートキーに対応するworktreeポートを割り当てる
#
# $1: worktreeのパス
# $2: worktreeポートキー
# REPLY: 割り当てたポート
# return: ポートを割り当てられた場合は0、それ以外は1
#
# example:
#  z.wtproxy._port.allocate /path/to/worktree worktree_port_1
z.wtproxy._port.allocate() {
  local worktree_path=$1
  local port_key=$2

  z.wtproxy._port.proxy $port_key || return 1
  local base_port=$REPLY

  z.wtproxy._port.used
  local used_ports=("${(@)REPLY}")
  z.wtproxy._port.proxies
  used_ports+=("${(@)REPLY}")

  for ((step=0; step<z_wtproxy_port_range; step++)); do
    local port=$((base_port + step))

    z.wtproxy._port.is.used $port ${used_ports[@]} && continue
    z.wtproxy._port.is.free $port || continue

    REPLY=$port
    return
  done

  z.io.error "No available worktree port for $port_key"
  return 1
}
