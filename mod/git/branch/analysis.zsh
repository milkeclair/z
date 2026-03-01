# show current branch
#
# REPLY: current branch name
# return: null
#
# example:
#   z.git.branch.current #=> "main"
z.git.branch.current() {
  z.git.branch.current.get && local current=$REPLY

  z.io $current
}
