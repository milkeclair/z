# check whether completion can be used in the current shell
#
# REPLY: null
# return: 0|1
#
# example:
#  z.completion.is._interactive
z.completion.is._interactive() {
  z.is.eq "$options[interactive]" on &&
    ! z.var.exists ZSH_EXECUTION_STRING
}
