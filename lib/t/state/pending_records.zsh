typeset z_t_pending_records=()

# 保留の記録を取得する
#
# REPLY: null
# return: 保留の記録の配列
#
# example:
#  z.t._state.pending_records  #=> ("record1" "record2" ...)
z.t._state.pending_records() {
  REPLY=("${z_t_pending_records[@]}")
}

# 保留の記録を追加する
#
# $1: 保留の記録
# REPLY: null
# return: null
#
# example:
#  z.t._state.pending_records.add "This is a pending record"
z.t._state.pending_records.add() {
  z_t_pending_records+=($1)
}
