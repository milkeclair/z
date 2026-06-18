# set a stored worktree port
#
# $1: worktree path
# $2: port key
# $3: port
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._state.port.set /path/to/worktree worktree_port_1 3001
z.wtproxy._state.port.set() {
  local worktree_path=$1
  local port_key=$2
  local port=$3

  z.wtproxy._state.port.state_key "$worktree_path" "$port_key"
  local state_key=$REPLY

  z_wtproxy_state_port[$state_key]=$port
}

# unset stored ports for a worktree path
#
# $1: worktree path
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._state.port.unset_path /path/to/worktree
z.wtproxy._state.port.unset_path() {
  local worktree_path=$1
  local state_key

  z.hash.keys z_wtproxy_state_port
  for state_key in ${(@)REPLY}; do
    z.str.start_with "$state_key" "$worktree_path|" && unset "z_wtproxy_state_port[$state_key]"
  done
}
