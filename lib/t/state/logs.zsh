typeset z_t_logs=()

# ログ配列の管理
#
# REPLY: ログの配列
# return: null
#
# example:
#  z_t_logs=("Suite" "Case")
#  z.t._state.logs
#  # REPLY: ("Suite" "Case")
z.t._state.logs() {
  REPLY=("${z_t_logs[@]}")
}

# ログを追加する
#
# $1: ログ
# REPLY: null
# return: null
#
# example:
#  z_t_logs=()
#  z.t._state.logs.add "This is a log entry"
#  z.t._state.logs
#  # REPLY: ("This is a log entry")
z.t._state.logs.add() {
  z_t_logs+=($1)
}

# contextごとのログを取得する
#
# $1: contextのインデックス
# REPLY: ログ
# return: null
#
# example:
#  z_t_logs=("Suite" "Case")
#  z.t._state.logs.context 1
#  # REPLY: "Suite"
z.t._state.logs.context() {
  local context=$1
  z.is.null $context && { REPLY=""; return 0; }
  REPLY=${z_t_logs[$context]:-""}
}

# contextごとのログを設定する
#
# $index: contextのインデックス
# $@: ログ
# REPLY: null
# return: null
#
# example:
#  z_t_logs=("Original log entry")
#  z.t._state.logs.context.set index=1 "Updated log entry"
#  z.t._state.logs.context 1
#  # REPLY: "Updated log entry"
z.t._state.logs.context.set() {
  local REPLY
  z.arg.named index $@ && local context=$REPLY
  z.arg.named.shift index $@ && local value=$REPLY

  local target_log=${z_t_logs[$context]}

  if z.is.not.null $target_log; then
    z_t_logs[$context]=$value
  fi
}
