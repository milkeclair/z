typeset z_t_pending_records=()

# 保留の記録を取得する
#
# REPLY: 保留の記録の配列
# return: null
#
# example:
#  z_t_pending_records=("1:2:3:4")
#  z.t._state.pending_records
#  # REPLY: ("1:2:3:4")
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
#  z_t_pending_records=()
#  z.t._state.pending_records.add "1:2:3"
#  z.t._state.pending_records
#  # REPLY: ("1:2:3")
z.t._state.pending_records.add() {
  z_t_pending_records+=($1)
}
