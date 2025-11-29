# list all defined functions and show their source files
#
# REPLY: null
# return: null
#
# example:
#  z.fn.list
z.fn.list() {
  z.fn._ensure_store

  local name

  for name in ${(k)z_fn_set}; do
    z.io $name
    z.io "Defined in ${z_fn_source[$name]}" indent=1
  done
}

# show the definition of a registered function
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.fn.show my_func
z.fn.show() {
  z.fn._ensure_store

  local name=$1

  if z.fn.not_exists $name; then
    z.io.error "Function $name does not exist."
    return 1
  fi

  z.io "Defined in: ${z_fn_source[$name]}"
  z.io $(which ${z_fn_set[$name]})
}
