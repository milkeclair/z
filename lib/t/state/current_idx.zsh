typeset -A z_t_current_idx=([describe]=0 [context]=0 [it]=0)

# contextの現在のインデックスを取得する
#
# $1: テストの区分（"describe"|"context"|"it"）
# REPLY: 現在のインデックス
# return: null
#
# example:
#  z.t._state.current_idx.set describe value=1
#  z.t._state.current_idx describe
#  # REPLY: 1
z.t._state.current_idx() {
  local context=$1
  REPLY=${z_t_current_idx[$context]}
}

# contextの現在のインデックスを設定する
#
# $value: インデックス値
# $@: テストの区分（"describe"|"context"|"it"）
# REPLY: null
# return: null
#
# example:
#  z.t._state.current_idx.set describe value=1
#  z.t._state.current_idx describe
#  # REPLY: 1
z.t._state.current_idx.set() {
  local REPLY
  z.arg.named value $@ && local value=$REPLY
  z.arg.named.shift value $@ && local context=$REPLY

  z_t_current_idx[$context]=$value
}

# 指定したcontextの現在のインデックスを増やす
#
# $1: テストの区分（"describe"|"context"|"it"）
# REPLY: 新しいインデックス値
# return: null
#
# example:
#  z_t_logs=("Suite")
#  z.t._state.current_idx.add describe
#  # REPLY: 1
#  # 変更後: z_t_current_idx[describe]=1、contextとitは0
z.t._state.current_idx.add() {
  local context=$1
  local logs=($z_t_logs)
  local idx=${#logs}

  case $context in
  "describe")
    z_t_current_idx[describe]=$idx
    z_t_current_idx[context]=0
    z_t_current_idx[it]=0
    ;;
  "context")
    z_t_current_idx[context]=$idx
    z_t_current_idx[it]=0
    ;;
  "it")
    z_t_current_idx[it]=$idx
    ;;
  esac

  REPLY=$idx
}
