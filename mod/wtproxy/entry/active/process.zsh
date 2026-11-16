# 状態のロックを保持しながら有効なエントリを読む
#
# REPLY: エントリのキーと値の組
# return: 有効なエントリを取得できた場合は0、それ以外は1
#
# example:
#  z.wtproxy._entry.active.locked
z.wtproxy._entry.active.locked() {
  z.wtproxy._state.load || return 1

  local worktree_path=$z_wtproxy_state_active_path
  z.is.null $worktree_path && return 1
  z.dir.not.exists "$worktree_path" && return 1
  z.wtproxy._state.path.has "$worktree_path" || return 1

  z.wtproxy._state.entry "$worktree_path"
}
