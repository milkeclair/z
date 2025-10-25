typeset -A z_t_mock_saved_indexes=()

# mock saved indexes management
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_saved_indexes  #=> ("index1" "index2" ...)
z.t._state.mock_saved_indexes() {
  z.return ${z_t_mock_saved_indexes[@]}
}

# get a mock saved index by context
#
# $1: context index
# REPLY: null
# return: saved index
#
# example:
#  z.t._state.mock_saved_indexes.context "0"  #=> "saved index at index 0"
z.t._state.mock_saved_indexes.context() {
  z.return ${z_t_mock_saved_indexes[$1]}
}

# add a mock saved index
#
# $1: context index
# $2: saved index value
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_saved_indexes.add "0" "saved index value"
z.t._state.mock_saved_indexes.add() {
  local key=$1
  local value=$2
  z_t_mock_saved_indexes[$key]=$value
}

# unset a mock saved index
#
# $1: context index
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_saved_indexes.unset "0"
z.t._state.mock_saved_indexes.unset() {
  unset "z_t_mock_saved_indexes[$1]" 2>/dev/null
}
