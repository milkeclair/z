# 状態のロックを保持しながら有効なエントリを読む
#
# REPLY: エントリのキーと値の組
# return: 有効なエントリを取得できた場合は0、それ以外は1
#
# example:
#  # 状態ファイルのactiveが実在する/tmp/worktreeを指し、エントリが登録済みの場合
#  z.wtproxy._entry.active.locked
#  local -A entry=($REPLY)
#  # entry[path]: "/tmp/worktree"
#  # return: 0
z.wtproxy._entry.active.locked() {
  z.wtproxy._state.load || return 1

  local worktree_path=$z_wtproxy_state_active_path
  z.is.null $worktree_path && return 1
  z.dir.not.exists "$worktree_path" && return 1
  z.wtproxy._state.path.has "$worktree_path" || return 1

  z.wtproxy._state.entry "$worktree_path"
}
