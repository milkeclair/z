# 失敗の記録を取得する
#
# REPLY: 失敗の記録
# return: null
#
# example:
#  z_t_failure_records=("1:2:3:4")
#  z.t._log.failure
#  # REPLY: ("1:2:3:4")
z.t._log.failure() {
  z.t._state.failure_records
}

# 失敗の記録を保存する
#
# REPLY: null
# return: null
#
# example:
#  z_t_logs=("Suite" "Context" "Case" "Error")
#  z_t_current_idx=(describe 1 context 2 it 3)
#  z_t_failure_records=()
#  z.t._log.failure.remember
#  # 変更後: z_t_failure_records=("1:2:3:4")
z.t._log.failure.remember() {
  local error_idx=${#z_t_logs[@]}

  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY

  z.t._state.failure_records.add "$d_idx:$c_idx:$i_idx:$error_idx"
}

# 失敗ログに色を付けて追加する
#
# $color: 色
# REPLY: null
# return: null
#
# example:
#  z_t_logs=("Suite")
#  z_t_current_idx=(describe 1 context 0 it 0)
#  z.t._log.failure.add color=red
#  # 変更後: z_t_logs[1]は赤色の"Suite"
z.t._log.failure.add() {
  z.arg.named color $@ && local color=$REPLY

  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY

  if z.int.is.not.zero $d_idx; then
    z.t._state.logs.context $d_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set index=$d_idx $REPLY
  fi

  if z.int.is.not.zero $c_idx; then
    z.t._state.logs.context $c_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set index=$c_idx $REPLY
  fi

  if z.int.is.not.zero $i_idx; then
    z.t._state.logs.context $i_idx
    z.str.color.red $REPLY

    z.t._state.logs.context.set index=$i_idx $REPLY
  fi
}

# 失敗ログを処理する
#
# $message: エラーメッセージ
# REPLY: null
# return: null
#
# example:
#  # 失敗件数0、compact=falseから実行する場合
#  z.t._log.failure.handle message="error message"
#  # 変更後の失敗件数: 1
#  # 結果: error messageのログと失敗の記録が追加される
z.t._log.failure.handle() {
  z.arg.named message $@ && local error_message=$REPLY

  z.str.indent level=4 message=$error_message
  z.str.color.red $REPLY
  z.t._state.logs.add $REPLY

  z.t._state.compact
  local is_compact=$REPLY

  if z.is.true $is_compact; then
    z.t._state.current_it_failures.increment
  fi

  z.t._state.failures.increment
  z.t._log.failure.remember
  z.t._log.failure.add color=red
}
