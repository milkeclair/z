# テストフレームワークのログ関数
#
# REPLY: ログの配列
# return: null
#
# example:
#  z_t_logs=("first" "second")
#  z.t._log
#  # REPLY: ("first" "second")
z.t._log() {
  z.t._state.logs
}
