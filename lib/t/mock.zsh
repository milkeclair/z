for mock_file in ${z_root}/lib/t/mock/*.zsh; do
  source ${mock_file} $1
done

# mock a function
#
# $1: function name
# $2: behavior (call_original|custom code)
# REPLY: null
# return: null
#
# example:
#  z.t.mock my_func "call_original"
z.t.mock() {
  local func_name=$1
  local behavior=$2
  local original_func_name="original_$func_name"

  z.t._state.mock_originals.add $func_name "$(functions $func_name)"
  z.t._state.mock_calls.set $func_name ""
  z.t._state.mock_last_func.set $func_name

  eval "$(functions $func_name | sed "s/^$func_name/$original_func_name/")"

  if z.eq $behavior "call_original"; then
    eval "$func_name() {
      $original_func_name \"\$@\"
      z.t._state.mock_calls.add \"$func_name\" \"\$@\"
    }"
  else
    eval "$func_name() {
      $behavior
      z.t._state.mock_calls.add \"$func_name\" \"\$@\"
    }"
  fi
}
