# ensure current entry while state lock is held
#
# $1: worktree path
# $2: branch label
# $3: activate flag
# REPLY: entry hash as key-value pairs
# return: 0 if entry is available, otherwise 1
#
# example:
#  z.wt_proxy._entry.current.locked "$path" "$branch" true
z.wt_proxy._entry.current.locked() {
  local worktree_path=$1
  local branch=$2
  local activate=$3

  z.wt_proxy._state.load || return 1
  z.wt_proxy._entry.ensure "$worktree_path" "$branch" || return 1
  local -A entry=("${(@)REPLY}")

  z.is.true $activate && z_wt_proxy_state_active_path=$worktree_path
  z.wt_proxy._state.save || return 1

  z.return.hash entry
}
