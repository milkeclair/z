# git branch alias
#
# $@: git branch options and arguments
# REPLY: null
# return: null
#
# example:
#   z.git.branch -a # show all branches
z.git.branch() {
  git branch "$@"
}

# alias for `git branch -a`
#
# $@: git branch options and arguments
# REPLY: null
# return: null
#
# example:
#   z.git.branch.all # show all branches
z.git.branch.all() {
  z.git.branch -a
}
