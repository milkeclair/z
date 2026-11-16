# テストスイート内のcontext
#
# $1: contextの説明
# REPLY: null
# return: null
#
# example:
#  # 有効なdescribe内で実行する場合
#  z.t.context "引数がある場合"; {
#    z.t.it "値を返す"; { z.t.expect "a" "a"; }
#  }
#  # 結果: 失敗件数は増えない
z.t.context() {
  local REPLY
  local context=$1

  z.t._state.skip.describe
  local describe_skip=$REPLY

  if z.is.true $describe_skip; then
    z.t._log.format "    " yellow "$context"
  else
    z.t._log.format "    " green "$context"
  fi

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "context"

  if z.is.true $describe_skip; then
    z.t._state.skip.context.set "true"
    z.t._state.skip.it.set "true"
  else
    z.t._state.skip.context.set "false"
    z.t._state.skip.it.set "false"
  fi
}

# テストスイート内のxcontext（保留扱い）
#
# $1: contextの説明
# REPLY: null
# return: null
#
# example:
#  z.t.xcontext "後で実装する場合"; {
#    z.t.it "値を返す"; { z.t.expect "a" "b"; }
#  }
#  # 結果: このcontext内の検証は保留になり、失敗件数は増えない
z.t.xcontext() {
  local REPLY
  local context=$1

  z.t._log.format "    " yellow "$context"

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "context"
  z.t._state.skip.describe
  z.t._state.skip.context.set "true"
  z.t._state.skip.it.set "true"
}
