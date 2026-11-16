z_t_states[pendings]=0

# 保留したテスト数を取得する
#
# REPLY: 保留したテスト数
# return: null
#
# example:
#  z_t_states[pendings]=3
#  z.t._state.pendings
#  # REPLY: 3
z.t._state.pendings() {
  REPLY=${z_t_states[pendings]}
}

# 保留したテスト数を1増やす
#
# REPLY: null
# return: null
#
# example:
#  # pendings=0の場合
#  z.t._state.pendings.increment
#  z.t._state.pendings
#  # REPLY: 1
z.t._state.pendings.increment() {
  (( z_t_states[pendings]++ ))
}
