# get the call arguments of the last call to the mocked function
# function name can be omitted to get the last mocked function
#
# $1: function name(optional)
# REPLY: array of arguments
# return: null
#
# example:
#  z.t.mock.result my_func
z.t.mock.result() {
  local func_name=$1

  if z.is_null $func_name; then
    z.t._state.mock_last_func
    func_name=$REPLY
  fi

  z.t._state.mock_calls.context $func_name
  if z.is_null $REPLY; then
    REPLY=()
  else
    z.str.split $REPLY ":"
  fi
}
