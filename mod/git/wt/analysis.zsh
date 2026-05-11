# get current git worktree root
#
# REPLY: absolute path to the worktree root
# return: 0 if root is found, otherwise 1
#
# example:
#  z.git.wt.root #=> "/path/to/worktree"
z.git.wt.root() {
  local worktree_path
  worktree_path=$(git rev-parse --show-toplevel)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  z.return "${worktree_path:A}"
}
