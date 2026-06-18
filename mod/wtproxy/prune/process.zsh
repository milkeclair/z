# prune stale worktree entries from state
#
# REPLY: prune result hash as key-value pairs
# return: 0 if state is updated, otherwise 1
#
# example:
#  z.wtproxy.prune._stale
z.wtproxy.prune._stale() {
  z.wtproxy._state.with_lock z.wtproxy.prune._stale.locked
}
