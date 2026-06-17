# set a stored worktree port
#
# $1: worktree path
# $2: port key
# $3: port
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy._state.port.set /path/to/worktree worktree_port_1 3001
z.wt_proxy._state.port.set() {
  local worktree_path=$1
  local port_key=$2
  local port=$3

  z.wt_proxy._state.port.state_key "$worktree_path" "$port_key"
  local state_key=$REPLY

  z_wt_proxy_state_port[$state_key]=$port
}

# unset stored ports for a worktree path
#
# $1: worktree path
# REPLY: null
# return: null
#
# example:
#  z.wt_proxy._state.port.unset_path /path/to/worktree
z.wt_proxy._state.port.unset_path() {
  local worktree_path=$1
  local state_key

  for state_key in ${(k)z_wt_proxy_state_port}; do
    z.str.start_with "$state_key" "$worktree_path|" && unset "z_wt_proxy_state_port[$state_key]"
  done
}
