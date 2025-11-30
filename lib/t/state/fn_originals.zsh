typeset -A z_t_fn_set_originals=()
typeset -A z_t_fn_source_originals=()

# get saved original function names
#
# REPLY: null
# return: ("func1" "func2" ...)
#
# example:
#  z.t._state.fn_originals  #=> ("func1" "func2" ...)
z.t._state.fn_originals() {
  z.hash.keys z_t_fn_set_originals
  z.return ${REPLY[@]}
}

# save original z_fn_set and z_fn_source
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.fn_originals.save
z.t._state.fn_originals.save() {
  z.fn._ensure_store

  z.hash.entries z_fn_set
  z_t_fn_set_originals=($REPLY)
  z.hash.entries z_fn_source
  z_t_fn_source_originals=($REPLY)
}

# restore original z_fn_set and z_fn_source
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.fn_originals.restore
z.t._state.fn_originals.restore() {
  z.fn._ensure_store

  z.hash.keys z_fn_set
  for key in $REPLY; do
    if (( ! ${+z_t_fn_set_originals[$key]} )); then
      local func_key=${z_fn_set[$key]}
      unfunction $func_key 2>/dev/null
    fi
  done

  z.hash.entries z_t_fn_set_originals
  z_fn_set=($REPLY)
  z.hash.entries z_t_fn_source_originals
  z_fn_source=($REPLY)
}
