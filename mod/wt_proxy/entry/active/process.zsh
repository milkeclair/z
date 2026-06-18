# read active entry while state lock is held
#
# REPLY: entry hash as key-value pairs
# return: 0 if active entry is available, otherwise 1
#
# example:
#  z.wt_proxy._entry.active.locked
z.wt_proxy._entry.active.locked() {
  z.wt_proxy._state.load || return 1

  local worktree_path=$z_wt_proxy_state_active_path
  z.is.null $worktree_path && return 1
  z.dir.not.exists "$worktree_path" && return 1
  z.wt_proxy._state.path.has "$worktree_path" || return 1

  z.wt_proxy._state.entry "$worktree_path"
}
