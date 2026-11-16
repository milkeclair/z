z_t_states[tests]=0

# 実行したテスト数を取得する
#
# REPLY: null
# return: テスト数
#
# example:
#  z.t._state.tests  #=> 10
z.t._state.tests() {
  REPLY=$z_t_states[tests]
}

# 実行したテスト数を1増やす
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.tests.increment
z.t._state.tests.increment() {
  (( z_t_states[tests]++ ))
}
