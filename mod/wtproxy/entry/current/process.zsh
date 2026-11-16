# 状態のロックを保持しながら現在のエントリを用意する
#
# $1: worktreeのパス
# $2: ブランチのラベル
# $3: 有効化フラグ
# REPLY: エントリのキーと値の組
# return: エントリを取得できた場合は0、それ以外は1
#
# example:
#  z.wtproxy._entry.current.locked "$path" "$branch" true
z.wtproxy._entry.current.locked() {
  local worktree_path=$1
  local branch=$2
  local activate=$3

  z.wtproxy._state.load || return 1
  z.wtproxy._entry.ensure "$worktree_path" "$branch" || return 1
  local -A entry=("${(@)REPLY}")

  z.is.true $activate && z_wtproxy_state_active_path=$worktree_path
  z.wtproxy._state.save || return 1

  z.hash.entries entry
}
