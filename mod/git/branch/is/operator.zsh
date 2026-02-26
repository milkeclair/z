# check if branch exists
#
# $1: branch name
# REPLY: null
# return: 0|1
#
# example:
#   z.git.branch.is.exists "feature-branch"
z.git.branch.is.exists() {
  local branch=$1

  command git show-ref --verify --quiet "refs/heads/$branch"
}
