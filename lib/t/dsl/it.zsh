# テストスイート内のitブロック
#
# $1: itの説明
# REPLY: null
# return: null
#
# example:
#  # 通常のdescribe/context内で、失敗件数0から実行する場合
#  z.t.it "値が一致する"; { z.t.expect 1 1; }
#  # 変更後の失敗件数: 0
z.t.it() {
  local REPLY=""

  local it=$1

  z.t._state.fn_originals.restore

  z.t._state.skip.describe
  local describe_skip=$REPLY
  z.t._state.skip.context
  local context_skip=$REPLY

  z.t._state.compact
  local is_compact=$REPLY

  if z.is.true $is_compact; then
    z.t._state.tests
    local test_count=$REPLY
    if z.int.is.gt $test_count 0; then
      z.t._state.current_it_failures
      local failures=$REPLY
      if z.int.is.zero $failures; then
        z.t._state.skip.it
        z.is.false $REPLY && z.t._log.dot.success
      else
        z.t._log.dot.failure
      fi
    fi
    z.t._state.current_it_failures.reset
  fi

  if z.is.true $describe_skip || z.is.true $context_skip; then
    z.t._log.format "      " yellow "$it"
  else
    z.t._log.format "      " green "$it"
  fi

  z.t._state.logs.add $REPLY
  z.t._state.current_idx.add "it"
  z.t._state.tests.increment

  if z.is.true $describe_skip || z.is.true $context_skip; then
    z.t._state.skip.it.set "true"
    z.t._state.pendings.increment

    z.t._state.current_idx "describe"
    local d_idx=$REPLY
    z.t._state.current_idx "context"
    local c_idx=$REPLY
    z.t._state.current_idx "it"
    local i_idx=$REPLY
    z.t._state.pending_records.add "$d_idx:$c_idx:$i_idx"

    if z.is.true $is_compact; then
      z.t._log.dot.pending
    fi
  else
    z.t._state.skip.it.set "false"
  fi
}

# テストスイート内のxitブロック（保留扱い）
#
# $1: itの説明
# REPLY: null
# return: null
#
# example:
#  # 通常のdescribe/context内で実行する場合
#  z.t.xit "後で実装する"; { z.t.expect 1 2; }
#  # 結果: 検証は保留になり、失敗件数は増えない
z.t.xit() {
  local REPLY=""

  local it=$1

  z.t._state.fn_originals.restore

  z.t._state.compact
  local is_compact=$REPLY

  if z.is.true $is_compact; then
    z.t._state.tests
    local test_count=$REPLY
    if z.int.is.gt $test_count 0; then
      z.t._state.current_it_failures
      local failures=$REPLY
      if z.int.is.zero $failures; then
        z.t._state.skip.it
        z.is.false $REPLY && z.t._log.dot.success
      else
        z.t._log.dot.failure
      fi
    fi
    z.t._state.current_it_failures.reset
  fi

  z.t._log.format "      " yellow "$it"
  z.t._state.logs.add $REPLY

  z.t._state.current_idx.add "it"
  z.t._state.tests.increment
  z.t._state.pendings.increment
  z.t._state.skip.it.set "true"

  z.t._state.current_idx "describe"
  local d_idx=$REPLY
  z.t._state.current_idx "context"
  local c_idx=$REPLY
  z.t._state.current_idx "it"
  local i_idx=$REPLY
  z.t._state.pending_records.add "$d_idx:$c_idx:$i_idx"

  if z.is.true $is_compact; then
    z.t._log.dot.pending
  fi
}
