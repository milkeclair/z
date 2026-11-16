typeset z_t_failure_records=()

# 失敗の記録を取得する
#
# REPLY: null
# return: 失敗の記録の配列
#
# example:
#  z.t._state.failure_records  #=> ("record1" "record2" ...)
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
#  z.t._state.failure_records.add "This is a failure record"
z.t._state.failure_records.add() {
  z_t_failure_records+=($1)
}
