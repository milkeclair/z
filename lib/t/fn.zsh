# unregister all test functions
#
# REPLY: null
# return: null
#
# example:
#  z.t.fn.unfn.all
z.t.fn.unfn.all() {
  local name

  for name in ${(k)z_t_fn_set}; do
    z.fn.delete $name
  done

  z_t_fn_set=()
}
