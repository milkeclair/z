z_t_states[pendings]=0

# 保留したテスト数を取得する
#
# REPLY: null
# return: 保留したテスト数
#
# example:
#  z.t._state.pendings  #=> 3
z.t._state.pendings() {
  REPLY=${z_t_states[pendings]}
}

# 保留したテスト数を1増やす
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.pendings.increment
z.t._state.pendings.increment() {
  (( z_t_states[pendings]++ ))
}
