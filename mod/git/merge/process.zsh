# safer merge
#
# $1: target branch to merge into current branch
# REPLY: null
# return: null
#
# example:
#  z.git.merge main
z.git.merge() {
  local target_branch=$1

  if z.str.is.empty $target_branch; then
    z.io.line
    z.io.error "Target branch is required for merging."
    return 1
  fi

  if z.git.status.is.dirty; then
    z.io.line
    z.io.error "You have uncommitted changes. Please commit or stash them before merging."
    return 1
  fi

  z.git.fetch
  git merge $target_branch
}
