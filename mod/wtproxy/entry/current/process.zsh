# 状態のロックを保持しながら現在のエントリを用意する
#
# $1: worktreeのパス
# $2: ブランチのラベル
# $3: 有効化フラグ
# REPLY: エントリのキーと値の組
# return: エントリを取得できた場合は0、それ以外は1
#
# example:
#  # /tmp/worktreeの有効なエントリが保存済みで、更新を保存できる場合
#  z.wtproxy._entry.current.locked /tmp/worktree feat/example true
#  local -A entry=($REPLY)
#  # entry[path]: "/tmp/worktree"
#  # entry[branch]: "feat/example"
#  # 変更後のactive: "/tmp/worktree"
#  # return: 0
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
