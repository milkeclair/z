z_t_states[current_it_failures]=0

# 現在のitの失敗件数を取得する
#
# REPLY: null
# return: 現在のitの失敗件数
#
# example:
#  z.t._state.current_it_failures  #=> 0
z.t._state.current_it_failures() {
  REPLY=$z_t_states[current_it_failures]
}

# 現在のitの失敗件数を増やす
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.current_it_failures.increment
z.t._state.current_it_failures.increment() {
  (( z_t_states[current_it_failures]++ ))
}

# 現在のitの失敗件数をリセットする
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.current_it_failures.reset
z.t._state.current_it_failures.reset() {
  z_t_states[current_it_failures]=0
}
