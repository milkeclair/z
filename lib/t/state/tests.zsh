z_t_states[tests]=0

# 実行したテスト数を取得する
#
# REPLY: テスト数
# return: null
#
# example:
#  z_t_states[tests]=10
#  z.t._state.tests
#  # REPLY: 10
z.t._state.tests() {
  REPLY=$z_t_states[tests]
}

# 実行したテスト数を1増やす
#
# REPLY: null
# return: null
#
# example:
#  # tests=0の場合
#  z.t._state.tests.increment
#  z.t._state.tests
#  # REPLY: 1
z.t._state.tests.increment() {
  (( z_t_states[tests]++ ))
}
