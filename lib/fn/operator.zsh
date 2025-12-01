for not_file in ${z_root}/lib/fn/not/*.zsh; do
  source ${not_file}
done

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
    z.is.eq $key $name && return 0
  done

  return 1
}
