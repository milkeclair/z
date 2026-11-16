z_t_states[mock_last_func]=""

# 最後にモックした関数名を取得する
#
# REPLY: null
# return: 関数名
#
# example:
#  z.t._state.mock_last_func  #=> "my_mocked_function"
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
#  z.t._state.mock_last_func.set "my_mocked_function"
z.t._state.mock_last_func.set() {
  z_t_states[mock_last_func]=$1
}
