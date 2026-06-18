# remove a worktree path from state
#
# $1: worktree path
# REPLY: null
# return: null
#
# example:
#  z.wtproxy._state.path.remove /path/to/worktree
z.wtproxy._state.path.remove() {
  local target_path=$1
  local remaining=()
  local worktree_path

  for worktree_path in $z_wtproxy_state_paths; do
    z.is.eq "$worktree_path" "$target_path" || remaining+=($worktree_path)
  done

  z_wtproxy_state_paths=($remaining)
  unset "z_wtproxy_state_branch[$target_path]"
  unset "z_wtproxy_state_compose[$target_path]"
  z.wtproxy._state.port.unset_path "$target_path"

  z.is.eq "$z_wtproxy_state_active_path" "$target_path" && z_wtproxy_state_active_path=""
  return 0
}
