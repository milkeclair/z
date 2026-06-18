# get current branch label
#
# REPLY: branch name or detached-<short HEAD>
# return: 0 if label is found, otherwise 1
#
# example:
#  z.git.branch.label.current #=> "main"
z.git.branch.label.current() {
  local branch
  branch=$(git branch --show-current)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  if z.is.not.null $branch; then
    z.return $branch
    return
  fi

  local head
  head=$(git rev-parse --short HEAD)
  exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  z.return "detached-$head"
}

# get branch label for a path
#
# $1: git worktree path
# REPLY: branch name or detached-<short HEAD>
# return: 0 if label is found, otherwise 1
#
# example:
#  z.git.branch.label.for /path/to/worktree #=> "main"
z.git.branch.label.for() {
  local worktree_path=$1
  local branch
  branch=$(git -C "$worktree_path" branch --show-current)
  local exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  if z.is.not.null $branch; then
    z.return $branch
    return
  fi

  local head
  head=$(git -C "$worktree_path" rev-parse --short HEAD)
  exit_status=$?
  z.int.is.not.zero $exit_status && return 1

  z.return "detached-$head"
}
