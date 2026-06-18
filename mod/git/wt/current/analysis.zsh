# get current git worktree root
#
# REPLY: absolute path to the worktree root
# return: 0 if root is found, otherwise 1
#
# example:
#  z.git.wt.current.root #=> "/path/to/worktree"
z.git.wt.current.root() {
  local worktree_path
  worktree_path=$(git rev-parse --show-toplevel)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  z.return "${worktree_path:A}"
}

# get current git worktree common git directory
#
# REPLY: absolute path to the common git directory
# return: 0 if common git directory is found, otherwise 1
#
# example:
#  z.git.wt.current.common_dir #=> "/path/to/repo/.git"
z.git.wt.current.common_dir() {
  local common_dir
  common_dir=$(git rev-parse --git-common-dir)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  z.return "${common_dir:A}"
}
