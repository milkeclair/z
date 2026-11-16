# 古いworktreeエントリを状態から削除する
#
# REPLY: 削除した古いエントリのキーと値の組
# return: 状態を更新できた場合は0、それ以外は1
#
# example:
#  z.wtproxy.prune._stale
z.wtproxy.prune._stale() {
  z.wtproxy._state.with_lock z.wtproxy.prune._stale.locked
}
