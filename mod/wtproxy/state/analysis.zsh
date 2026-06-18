# build an entry hash from state for a worktree path
#
# $1: worktree path
# REPLY: entry hash as key-value pairs
# return: null
#
# example:
#  z.wtproxy._state.entry /path/to/worktree
z.wtproxy._state.entry() {
  local worktree_path=$1

  local -A entry=(
    path $worktree_path
    branch $z_wtproxy_state_branch[$worktree_path]
    compose_project_name $z_wtproxy_state_compose[$worktree_path]
  )

  z.wtproxy._port.keys
  for port_key in ${(@)REPLY}; do
    z.wtproxy._state.port.get "$worktree_path" "$port_key"
    entry[$port_key]=$REPLY
  done

  z.return.hash entry
}
