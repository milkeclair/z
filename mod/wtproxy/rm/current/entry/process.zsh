# 状態のロックを保持しながら、現在の削除可能なエントリを取得する
#
# $1: worktreeのパス
# REPLY: エントリのキーと値の組
# return: 現在のエントリが存在する場合は0、それ以外は1
#
# example:
#  # 状態ファイルに/tmp/worktreeのエントリがある場合
#  z.wtproxy.rm._current.entry.locked /tmp/worktree
#  local -A entry=($REPLY)
#  # entry[path]: "/tmp/worktree"
#  # return: 0
z.wtproxy.rm._current.entry.locked() {
  local worktree_path=$1

  z.wtproxy._state.load || return 1
  z.wtproxy._state.path.has "$worktree_path" || {
    z.io.error "entry not found: $worktree_path"
    return 1
  }

  z.wtproxy._state.entry "$worktree_path"
}
