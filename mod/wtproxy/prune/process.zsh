# 古いworktreeエントリを状態から削除する
#
# REPLY: 削除した古いエントリのキーと値の組
# return: 状態を更新できた場合は0、それ以外は1
#
# example:
#  # 不存在のworktreeが1件だけあり、Composeリソースの削除と保存が成功する場合
#  z.wtproxy.prune._stale
#  local -A result=($REPLY)
#  # result[entries_count]: 0
#  # result[pruned_projects]: "sample_feat_example_b671591e"
#  # return: 0
z.wtproxy.prune._stale() {
  z.wtproxy._state.with_lock z.wtproxy.prune._stale.locked
}
