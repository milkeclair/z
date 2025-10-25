typeset -A z_t_mock_originals=()

# mock originals management
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals  #=> ("func1" "func2" ...)
z.t._state.mock_originals() {
  z.return ${(k)z_t_mock_originals[@]}
}

# get a mock original by function name
#
# $1: function name
# REPLY: null
# return: original function definition
#
# example:
#  z.t._state.mock_originals.context "my_func"  #=> "original function definition"
z.t._state.mock_originals.context() {
  z.return ${z_t_mock_originals[$1]}
}

# add a mock original
#
# $1: function name
# $2: original function definition
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals.add "my_func" "original function definition"
z.t._state.mock_originals.add() {
  local func_name=$1
  local original_func=$2

  z_t_mock_originals[$func_name]=$original_func
}

# unset a mock original
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals.unset "my_func"
z.t._state.mock_originals.unset() {
  unset "z_t_mock_originals[$1]" 2>/dev/null
}
