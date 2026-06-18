# prune stale entries while state lock is held
#
# REPLY: prune result hash as key-value pairs
# return: 0 if state is updated, otherwise 1
#
# example:
#  z.wt_proxy.prune._stale.locked
z.wt_proxy.prune._stale.locked() {
  z.wt_proxy._state.load || return 1

  local remaining=()
  local pruned_projects=()

  for worktree_path in $z_wt_proxy_state_paths; do
    if z.dir.exists "$worktree_path"; then
      remaining+=($worktree_path)
    else
      z.is.not.null $z_wt_proxy_state_compose[$worktree_path] && pruned_projects+=($z_wt_proxy_state_compose[$worktree_path])
      unset "z_wt_proxy_state_branch[$worktree_path]"
      unset "z_wt_proxy_state_compose[$worktree_path]"
      z.wt_proxy._state.port.unset_path "$worktree_path"
    fi
  done

  z_wt_proxy_state_paths=($remaining)
  if z.is.not.null $z_wt_proxy_state_active_path && z.dir.not.exists "$z_wt_proxy_state_active_path"; then
    z_wt_proxy_state_active_path=""
  fi

  z.wt_proxy._state.save || return 1

  local -A result=(
    entries_count ${#z_wt_proxy_state_paths[@]}
    pruned_projects "${pruned_projects[*]}"
  )
  z.return.hash result
}
