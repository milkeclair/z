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
  (( ${(P)+1} ))
}

# determine if a variable is settled (declared and assigned)
#
# $1: variable name
# REPLY: null
# return: 0\1
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.sets TEST_VAR
#   echo $?  # outputs 0
z.var.sets() {
  z.var.exists $1 && z.is_not_null ${(P)1}
}
