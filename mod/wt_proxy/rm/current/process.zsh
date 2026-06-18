# get the current worktree entry before removing it
#
# REPLY: entry hash as key-value pairs
# return: 0 if current entry exists, otherwise 1
#
# example:
#  z.wt_proxy.rm._current.entry
z.wt_proxy.rm._current.entry() {
  z.git.wt.root || return 1
  local worktree_path=$REPLY

  z.wt_proxy._state.with_lock z.wt_proxy.rm._current.entry.locked "$worktree_path"
}

# remove the current worktree entry while state lock is held
#
# $1: worktree path
# $2: expected compose project name
# REPLY: remove result hash as key-value pairs
# return: 0 if current entry is removed, otherwise 1
#
# example:
#  z.wt_proxy.rm._current.locked /path/to/worktree project_branch_hash
z.wt_proxy.rm._current.locked() {
  local worktree_path=$1
  local expected_project=$2

  z.wt_proxy._state.load || return 1
  z.wt_proxy._state.path.has "$worktree_path" || {
    z.io.error "entry not found: $worktree_path"
    return 1
  }

  local removed_project=$z_wt_proxy_state_compose[$worktree_path]
  if z.is.not.null "$expected_project" && z.is.not.eq "$removed_project" "$expected_project"; then
    z.io.error "entry changed: $worktree_path"
    return 1
  fi

  z.wt_proxy._state.path.remove "$worktree_path"
  z.wt_proxy._state.save || return 1

  local -A result=(
    removed_path $worktree_path
    removed_project $removed_project
    entries_count ${#z_wt_proxy_state_paths[@]}
  )
  z.return.hash result
}
