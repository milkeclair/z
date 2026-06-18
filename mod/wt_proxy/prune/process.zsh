# prune stale worktree entries from state
#
# REPLY: prune result hash as key-value pairs
# return: 0 if state is updated, otherwise 1
#
# example:
#  z.wt_proxy.prune._stale
z.wt_proxy.prune._stale() {
  z.wt_proxy._state.with_lock z.wt_proxy.prune._stale.locked
}
