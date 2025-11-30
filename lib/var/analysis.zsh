# get the value of a variable by its name
#
# $1: variable name
# REPLY: variable value or null if not exists
# return: null
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.get TEST_VAR
#   echo $REPLY  # outputs "Hello, World!"
z.var.get() {
  local var_name=$1

  if z.var.exists $var_name; then
    z.return ${(P)var_name}
  else
    z.return null
  fi
}
