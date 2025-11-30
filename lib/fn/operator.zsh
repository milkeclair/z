# check if a function exists
#
# $1: function name
# REPLY: null
# return 0|1
#
# example:
#  if z.fn.exists my_func
z.fn.exists() {
  z.fn._ensure_store

  local name=$1
  local key

  z.hash.keys z_fn_set
  for key in $REPLY; do
    z.eq $key $name && return 0
  done

  return 1
}

# check if a function does not exist
#
# $1: function name
# REPLY: null
# return 0|1
#
# example:
#  if z.fn.not_exists my_func
z.fn.not_exists() {
  z.fn._ensure_store

  local name=$1

  z.fn.exists $name && return 1

  return 0
}
