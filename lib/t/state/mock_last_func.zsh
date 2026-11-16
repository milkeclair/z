z_t_states[mock_last_func]=""

# 最後にモックした関数名を取得する
#
# REPLY: 関数名
# return: null
#
# example:
#  z.t._state.mock_last_func.set my_func
#  z.t._state.mock_last_func
#  # REPLY: "my_func"
z.t._state.mock_last_func() {
  REPLY=$z_t_states[mock_last_func]
}

# 最後にモックした関数名を設定する
#
# $1: 関数名
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_last_func.set my_mocked_function
#  z.t._state.mock_last_func
#  # REPLY: "my_mocked_function"
z.t._state.mock_last_func.set() {
  z_t_states[mock_last_func]=$1
}
