typeset -A z_t_mock_originals=()

# mock originals management
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals  #=> ("func1" "func2" ...)
z.t._state.mock_originals() {
  z.hash.keys z_t_mock_originals
  z.return ${REPLY[@]}
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
# $name: function name
# $2: original function definition
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals.add name=my_func "original function definition"
z.t._state.mock_originals.add() {
  local REPLY
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named.shift name $@ && local original_func=$REPLY

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
