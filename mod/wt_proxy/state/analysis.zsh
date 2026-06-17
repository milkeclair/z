# build an entry hash from state for a worktree path
#
# $1: worktree path
# REPLY: entry hash as key-value pairs
# return: null
#
# example:
#  z.wt_proxy._state.entry /path/to/worktree
z.wt_proxy._state.entry() {
  local worktree_path=$1

  local -A entry=(
    path $worktree_path
    branch $z_wt_proxy_state_branch[$worktree_path]
    compose_project_name $z_wt_proxy_state_compose[$worktree_path]
    updated_at $z_wt_proxy_state_updated_at[$worktree_path]
  )

  z.wt_proxy._port.keys
  for port_key in ${(@)REPLY}; do
    z.wt_proxy._state.port.get "$worktree_path" "$port_key"
    entry[$port_key]=$REPLY
  done

  z.return.hash entry
}
