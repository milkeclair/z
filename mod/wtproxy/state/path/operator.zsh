# check if state has a worktree path
#
# $1: worktree path
# REPLY: null
# return: 0 if path exists in state, otherwise 1
#
# example:
#  z.wtproxy._state.path.has /path/to/worktree
z.wtproxy._state.path.has() {
  local target_path=$1
  local worktree_path

  for worktree_path in $z_wtproxy_state_paths; do
    z.is.eq "$worktree_path" "$target_path" && return 0
  done

  return 1
}
