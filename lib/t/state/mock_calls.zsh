typeset -A z_t_mock_calls=()

# mock calls management
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls  #=> ("call1" "call2" ...)
z.t._state.mock_calls() {
  z.return ${z_t_mock_calls[@]}
}

# get mock calls by function name
#
# $1: function name
# REPLY: null
# return: mock calls
#
# example:
#  z.t._state.mock_calls.context "my_func"  #=> "mock calls for my_func"
z.t._state.mock_calls.context() {
  z.return ${z_t_mock_calls[$1]}
}

# add a mock call
#
# $name: function name
# $@: arguments
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.add name=my_func "arg1" "arg2"
z.t._state.mock_calls.add() {
  local REPLY
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named.shift name $@ && local args=$REPLY

  if z.is_not_null ${z_t_mock_calls[$func_name]}; then
    z_t_mock_calls[$func_name]="${z_t_mock_calls[$func_name]}:$args"
  else
    z_t_mock_calls[$func_name]=$args
  fi
}

# set mock calls for a function
#
# $name: function name
# $value: value
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.set name=my_func "value=new value"
z.t._state.mock_calls.set() {
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named value $@ && local value=$REPLY

  z_t_mock_calls[$func_name]=$value
}

# unset mock calls for a function
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.unset "my_func"
z.t._state.mock_calls.unset() {
  unset "z_t_mock_calls[$1]" 2>/dev/null
}
