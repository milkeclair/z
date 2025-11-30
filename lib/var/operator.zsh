# determine if a variable exists
#
# $1: variable name
# REPLY: null
# return: 0\1
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.exists TEST_VAR
#   echo $?  # outputs 0
z.var.exists() {
  [[ -v $1 ]]
}
