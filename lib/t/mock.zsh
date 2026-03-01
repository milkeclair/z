# mock a function or external command
#
# $name: function or command name
# $behavior?: behavior (call_original|custom code)
# REPLY: null
# return: null
#
# example:
#  z.t.mock name=my_func behavior=call_original
z.t.mock() {
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named behavior $@ && local behavior=$REPLY
  local original_func_name="original_$func_name"
  local nonfunctional="_nonfunctional"

  if functions $func_name >/dev/null 2>&1; then
    z.t._state.mock_originals.add name=$func_name "$(functions $func_name)"
    functions -c $func_name $original_func_name
  else
    z.t._state.mock_originals.add name=$func_name $nonfunctional
    eval "$original_func_name() {
      command $func_name \"\$@\"
    }"
  fi

  z.t._state.mock_calls.set name=$func_name value=""
  z.t._state.mock_last_func.set $func_name

  if z.is.eq $behavior "call_original"; then
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
