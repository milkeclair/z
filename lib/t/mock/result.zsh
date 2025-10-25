# get the call arguments of the last call to the mocked function
# function name can be omitted to get the last mocked function
#
# $name: function name(optional)
# REPLY: array of arguments
# return: null
#
# example:
#  z.t.mock.result name=my_func
z.t.mock.result() {
  z.arg.named name $@ && local func_name=$REPLY

  if z.is_null $func_name; then
    z.t._state.mock_last_func
    func_name=$REPLY
  fi

  z.t._state.mock_calls.context $func_name
  if z.is_null $REPLY; then
    REPLY=()
  else
    z.str.split str=$REPLY delimiter=:
  fi
}
