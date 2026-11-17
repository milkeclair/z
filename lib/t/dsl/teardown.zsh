# テスト終了時に呼び出す後片付け用の関数
#
# REPLY: null
# return: null
#
# example:
#  # テスト終了時に、失敗件数0の場合
#  z.t.teardown
#  # 結果: モックと一時ファイルを片付け、成功の要約を表示する
z.t.teardown() {
  z.t.mock.unmock.all
  z.t._remove_tmp_dir

  local error_flag_file="/tmp/z_t_error_$$"
  if z.file.exists $error_flag_file; then
    z.str.split.line "$(<$error_flag_file)" empty=drop
    local error_lines=("${REPLY[@]}")
    z.arr.count $error_lines
    local error_count=$REPLY

    local i
    for ((i=1; i<=error_count; i++)); do
      local error_message=${error_lines[$i]}
      z.t._log.failure.handle message=$error_message
    done

    z.dir.remove path=$error_flag_file
  fi

  z.t._state.compact
  if z.is.true $REPLY; then
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
  fi

  z.t._log.show

  z.t._state.failures
  z.int.is.not.zero $REPLY && exit 1
}
