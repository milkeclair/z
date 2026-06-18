# get the current removable entry while state lock is held
#
# $1: worktree path
# REPLY: entry hash as key-value pairs
# return: 0 if current entry exists, otherwise 1
#
# example:
#  z.wtproxy.rm._current.entry.locked /path/to/worktree
z.wtproxy.rm._current.entry.locked() {
  local worktree_path=$1

  z.wtproxy._state.load || return 1
  z.wtproxy._state.path.has "$worktree_path" || {
    z.io.error "entry not found: $worktree_path"
    return 1
  }

  z.wtproxy._state.entry "$worktree_path"
}
