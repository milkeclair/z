# 現在のworktreeのエントリを削除前に取得する
#
# REPLY: エントリのキーと値の組
# return: 現在のエントリが存在する場合は0、それ以外は1
#
# example:
#  z.wtproxy.rm._current.entry
z.wtproxy.rm._current.entry() {
  z.git.wt.current.root || return 1
  local worktree_path=$REPLY

  z.wtproxy._state.with_lock z.wtproxy.rm._current.entry.locked "$worktree_path"
}

# 状態のロックを保持しながら現在のworktreeエントリを削除する
#
# $1: worktreeのパス
# $2: 期待するComposeプロジェクト名
# REPLY: 削除結果のキーと値の組
# return: 現在のエントリを削除できた場合は0、それ以外は1
#
# example:
#  z.wtproxy.rm._current.locked /path/to/worktree project_branch_hash
z.wtproxy.rm._current.locked() {
  local worktree_path=$1
  local expected_project=$2

  z.wtproxy._state.load || return 1
  z.wtproxy._state.path.has "$worktree_path" || {
    z.io.error "entry not found: $worktree_path"
    return 1
  }

  local removed_project=$z_wtproxy_state_compose[$worktree_path]
  if z.is.not.null "$expected_project" && z.is.not.eq "$removed_project" "$expected_project"; then
    z.io.error "entry changed: $worktree_path"
    return 1
  fi

  z.wtproxy._state.path.remove "$worktree_path"
  z.wtproxy._state.save || return 1

  local -A result=(
    removed_path $worktree_path
    removed_project $removed_project
    entries_count ${#z_wtproxy_state_paths[@]}
  )
  z.hash.entries result
}
