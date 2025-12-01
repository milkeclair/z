# check if a function does not exist
#
# $1: function name
# REPLY: null
# return 0|1
#
# example:
#  if z.fn.not.exists my_func
z.fn.not.exists() {
  z.fn._ensure_store

  local name=$1

  z.fn.exists $name && return 1

  return 0
}
