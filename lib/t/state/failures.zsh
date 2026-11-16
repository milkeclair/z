z_t_states[failures]=0

# 失敗したテスト数を取得する
#
# REPLY: 失敗したテスト数
# return: null
#
# example:
#  z_t_states[failures]=2
#  z.t._state.failures
#  # REPLY: 2
z.t._state.failures() {
  REPLY=${z_t_states[failures]}
}

# 失敗したテスト数を1増やす
#
# REPLY: null
# return: null
#
# example:
#  # failures=0の場合
#  z.t._state.failures.increment
#  z.t._state.failures
#  # REPLY: 1
z.t._state.failures.increment() {
  (( z_t_states[failures]++ ))
}
