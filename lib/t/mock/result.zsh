# モックした関数の最後の呼び出しの引数を取得する
# 関数名を省略すると、最後にモックした関数を取得する
#
# $name?: 関数名
# REPLY: 引数の配列
# return: null
#
# example:
#  z.t.mock name=my_func
#  my_func arg1 arg2
#  z.t.mock.result name=my_func
#  # REPLY: ("arg1 arg2")
#  z.t.mock.unmock name=my_func
z.t.mock.result() {
  z.arg.named name $@ && local func_name=$REPLY

  if z.is.null $func_name; then
    z.t._state.mock_last_func
    func_name=$REPLY
  fi

  z.t._state.mock_calls.context $func_name
  if z.is.null $REPLY; then
    REPLY=()
  else
    z.str.split str=$REPLY delimiter="$z_t_mock_call_sep"
  fi
}
