typeset z_t_failure_records=()

# 失敗の記録を取得する
#
# REPLY: 失敗の記録の配列
# return: null
#
# example:
#  z_t_failure_records=("1:2:3:4")
#  z.t._state.failure_records
#  # REPLY: ("1:2:3:4")
z.t._state.failure_records() {
  REPLY=("${z_t_failure_records[@]}")
}

# 失敗の記録を追加する
#
# $1: 失敗の記録
# REPLY: null
# return: null
#
# example:
#  z_t_failure_records=()
#  z.t._state.failure_records.add "1:2:3:4"
#  z.t._state.failure_records
#  # REPLY: ("1:2:3:4")
z.t._state.failure_records.add() {
  z_t_failure_records+=($1)
}
