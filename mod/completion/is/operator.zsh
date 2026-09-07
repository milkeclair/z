# check whether completion can be used in the current shell
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.is._interactive
z.completion.is._interactive() {
  [[ -o interactive && ! -v ZSH_EXECUTION_STRING ]]
}
