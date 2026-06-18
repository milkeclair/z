# remove the current worktree entry from state
#
# $expected_project?: expected compose project name
# REPLY: remove result hash as key-value pairs
# return: 0 if current entry is removed, otherwise 1
#
# example:
#  z.wtproxy.rm._current expected_project=project_branch_hash
z.wtproxy.rm._current() {
  z.arg.named expected_project $@ default="" && local expected_project=$REPLY

  z.git.wt.current.root || return 1
  local worktree_path=$REPLY

  z.wtproxy._state.with_lock z.wtproxy.rm._current.locked "$worktree_path" "$expected_project"
}
