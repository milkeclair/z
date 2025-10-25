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
# $1: function name
# $2: arguments
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.add "my_func" "arg1" "arg2"
z.t._state.mock_calls.add() {
  local func_name=$1 && shift
  local args=$@

  if z.is_not_null ${z_t_mock_calls[$func_name]}; then
    z_t_mock_calls[$func_name]="${z_t_mock_calls[$func_name]}:$args"
  else
    z_t_mock_calls[$func_name]=$args
  fi
}

# set mock calls for a function
#
# $1: function name
# $2: value
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.set "my_func" "new value"
z.t._state.mock_calls.set() {
  local func_name=$1
  local value=$2

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
