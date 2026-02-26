# show current branch
#
# REPLY: current branch name
# return: null
#
# example:
#   z.git.branch.current.show #=> "main"
z.git.branch.current.show() {
  z.git.branch.current && local current=$REPLY

  z.io $current
}
