# 現在のworktreeエントリを状態から削除する
#
# $expected_project?: 期待するComposeプロジェクト名
# REPLY: 削除結果のキーと値の組
# return: 現在のエントリを削除できた場合は0、それ以外は1
#
# example:
#  z.wtproxy.rm._current expected_project=project_branch_hash
z.wtproxy.rm._current() {
  z.arg.named expected_project $@ default="" && local expected_project=$REPLY

  z.git.wt.current.root || return 1
  local worktree_path=$REPLY

  z.wtproxy._state.with_lock z.wtproxy.rm._current.locked "$worktree_path" "$expected_project"
}
