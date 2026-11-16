z_t_states[failures]=0

# 失敗したテスト数を取得する
#
# REPLY: null
# return: 失敗したテスト数
#
# example:
#  z.t._state.failures  #=> 2
z.t._state.failures() {
  REPLY=${z_t_states[failures]}
}

# 失敗したテスト数を1増やす
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.failures.increment
z.t._state.failures.increment() {
  (( z_t_states[failures]++ ))
}
