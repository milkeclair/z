typeset -A z_t_mock_calls=()
typeset z_t_mock_call_sep=$'\x1e'

# モックの呼び出しの管理
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls  #=> ("call1" "call2" ...)
z.t._state.mock_calls() {
  REPLY=("${z_t_mock_calls[@]}")
}

# 関数名に対応するモックの呼び出しを取得する
#
# $1: 関数名
# REPLY: null
# return: モックの呼び出し
#
# example:
#  z.t._state.mock_calls.context "my_func"  #=> "mock calls for my_func"
z.t._state.mock_calls.context() {
  REPLY=${z_t_mock_calls[$1]}
}

# モックの呼び出しを追加する
#
# $name: 関数名
# $@: 引数
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.add name=my_func "arg1" "arg2"
z.t._state.mock_calls.add() {
  local REPLY
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named.shift name $@ && local args=$REPLY

  if z.is.not.null ${z_t_mock_calls[$func_name]}; then
    z_t_mock_calls[$func_name]="${z_t_mock_calls[$func_name]}${z_t_mock_call_sep}${args}"
  else
    z_t_mock_calls[$func_name]=$args
  fi
}

# 関数のモック呼び出しを設定する
#
# $name: 関数名
# $value: 値
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.set name=my_func "value=new value"
z.t._state.mock_calls.set() {
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named value $@ && local value=$REPLY

  z_t_mock_calls[$func_name]=$value
}

# 関数のモック呼び出しを削除する
#
# $1: 関数名
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_calls.unset "my_func"
z.t._state.mock_calls.unset() {
  unset "z_t_mock_calls[$1]" 2>/dev/null
}
