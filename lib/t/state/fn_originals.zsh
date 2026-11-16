typeset -A z_t_fn_set_originals=()
typeset -A z_t_fn_source_originals=()

# 保存した元の関数名を取得する
#
# REPLY: null
# return: ("func1" "func2" ...)
#
# example:
#  z.t._state.fn_originals  #=> ("func1" "func2" ...)
z.t._state.fn_originals() {
  z.hash.keys z_t_fn_set_originals
  return 0
}

# 元のz_fn_setとz_fn_sourceを保存する
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

# 元のz_fn_setとz_fn_sourceを復元する
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
    if z.hash.has.not.key z_t_fn_set_originals key=$key; then
      local func_key=${z_fn_set[$key]}
      unfunction $func_key 2>/dev/null
    fi
  done

  z.hash.entries z_t_fn_set_originals
  z_fn_set=($REPLY)
  z.hash.entries z_t_fn_source_originals
  z_fn_source=($REPLY)
}
