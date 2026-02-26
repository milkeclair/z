# check if branch exists
#
# $1: branch name
# REPLY: null
# return: 0|1
#
# example:
#   z.git.branch.is.not.exists "feature-branch"
z.git.branch.is.not.exists() {
  ! z.git.branch.is.exists $1
}
