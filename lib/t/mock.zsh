for mock_file in ${z_root}/lib/t/mock/*.zsh; do
  source ${mock_file} $1
done

# mock a function
#
# $name: function name
# $behavior: behavior (call_original|custom code)
# REPLY: null
# return: null
#
# example:
#  z.t.mock name=my_func behavior=call_original
z.t.mock() {
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named behavior $@ && local behavior=$REPLY
  local original_func_name="original_$func_name"

  z.t._state.mock_originals.add name=$func_name "$(functions $func_name)"
  z.t._state.mock_calls.set name=$func_name value=""
  z.t._state.mock_last_func.set $func_name

  eval "$(functions $func_name | sed "s/^$func_name/$original_func_name/")"

  if z.eq $behavior "call_original"; then
    eval "$func_name() {
      $original_func_name \"\$@\"
      z.t._state.mock_calls.add name=\"$func_name\" \"\$@\"
    }"
  else
    eval "$func_name() {
      $behavior
      z.t._state.mock_calls.add name=\"$func_name\" \"\$@\"
    }"
  fi
}
