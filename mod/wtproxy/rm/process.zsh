# 現在のworktreeエントリを状態から削除する
#
# $expected_project?: 期待するComposeプロジェクト名
# REPLY: 削除結果のキーと値の組
# return: 現在のエントリを削除できた場合は0、それ以外は1
#
# example:
#  # 現在のworktreeが/tmp/worktreeで、Compose名が一致する場合
#  z.wtproxy.rm._current expected_project=sample_feat_example_b671591e
#  local -A result=($REPLY)
#  # result[removed_path]: "/tmp/worktree"
#  # result[removed_project]: "sample_feat_example_b671591e"
#  # return: 0
z.wtproxy.rm._current() {
  z.arg.named expected_project $@ default="" && local expected_project=$REPLY

  z.git.wt.current.root || return 1
  local worktree_path=$REPLY

  z.wtproxy._state.with_lock z.wtproxy.rm._current.locked "$worktree_path" "$expected_project"
}
