# get the value of a variable by its name
#
# $1: variable name
# $literal?: preserve values and array elements without conversion (default: false)
# REPLY: variable value or null if not exists
# return: null
#
# example:
#   local TEST_VAR="Hello, World!"
#   z.var.get TEST_VAR
#   echo $REPLY  # outputs "Hello, World!"
z.var.get() {
  local var_name=$1
  z.arg.named literal $@ default=false && local literal=$REPLY

  if z.var.exists $var_name; then
    if z.is.true $literal; then
      REPLY=("${(@P)var_name}")
    else
      z.return ${(P)var_name}
    fi
  else
    z.return null
  fi
}
