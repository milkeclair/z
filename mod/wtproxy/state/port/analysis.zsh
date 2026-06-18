# get a composite state key for a worktree port
#
# $1: worktree path
# $2: port key
# REPLY: composite state key
# return: null
#
# example:
#  z.wtproxy._state.port.state_key /path/to/worktree worktree_port_1
z.wtproxy._state.port.state_key() {
  local worktree_path=$1
  local port_key=$2

  z.return "${worktree_path}|${port_key}"
}

# get a stored worktree port
#
# $1: worktree path
# $2: port key
# REPLY: stored port|null
# return: null
#
# example:
#  z.wtproxy._state.port.get /path/to/worktree worktree_port_1
z.wtproxy._state.port.get() {
  local worktree_path=$1
  local port_key=$2

  z.wtproxy._state.port.state_key "$worktree_path" "$port_key"
  local state_key=$REPLY

  z.return $z_wtproxy_state_port[$state_key]
}
