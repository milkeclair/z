z_t_states[mock_last_func]=""

# get the last mocked function name
#
# REPLY: null
# return: function name
#
# example:
#  z.t._state.mock_last_func  #=> "my_mocked_function"
z.t._state.mock_last_func() {
  z.return $z_t_states[mock_last_func]
}

# set the last mocked function name
#
# $1: function name
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_last_func.set "my_mocked_function"
z.t._state.mock_last_func.set() {
  z_t_states[mock_last_func]=$1
}
