# 状態のロックを保持しながら古いエントリを削除する
#
# REPLY: 削除した古いエントリのキーと値の組
# return: 状態を更新できた場合は0、それ以外は1
#
# example:
#  z.wtproxy.prune._stale.locked
z.wtproxy.prune._stale.locked() {
  z.wtproxy._state.load || return 1

  local remaining=()
  local pruned_projects=()

  for worktree_path in $z_wtproxy_state_paths; do
    if z.dir.exists "$worktree_path"; then
      remaining+=($worktree_path)
    else
      z.is.not.null $z_wtproxy_state_compose[$worktree_path] && pruned_projects+=($z_wtproxy_state_compose[$worktree_path])
    fi
  done

  for project_name in $pruned_projects; do
    z.wtproxy._docker.prune "$project_name" || return 1
  done

  for worktree_path in $z_wtproxy_state_paths; do
    if z.dir.not.exists "$worktree_path"; then
      unset "z_wtproxy_state_branch[$worktree_path]"
      unset "z_wtproxy_state_compose[$worktree_path]"
      z.wtproxy._state.port.unset_path "$worktree_path"
    fi
  done

  z_wtproxy_state_paths=($remaining)
  if z.is.not.null $z_wtproxy_state_active_path && z.dir.not.exists "$z_wtproxy_state_active_path"; then
    z_wtproxy_state_active_path=""
  fi

  z.wtproxy._state.save || return 1

  local -A result=(
    entries_count ${#z_wtproxy_state_paths[@]}
    pruned_projects "${pruned_projects[*]}"
  )
  z.hash.entries result
}
