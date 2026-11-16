typeset -A z_t_mock_originals=()

# モック元の定義の管理
#
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals  #=> ("func1" "func2" ...)
z.t._state.mock_originals() {
  z.hash.keys z_t_mock_originals
  return 0
}

# 関数名に対応するモック元の定義を取得する
#
# $1: 関数名
# REPLY: null
# return: 元の関数定義
#
# example:
#  z.t._state.mock_originals.context "my_func"  #=> "original function definition"
z.t._state.mock_originals.context() {
  REPLY=${z_t_mock_originals[$1]}
}

# モック元の定義を追加する
#
# $name: 関数名
# $2: 元の関数定義
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals.add name=my_func "original function definition"
z.t._state.mock_originals.add() {
  local REPLY
  z.arg.named name $@ && local func_name=$REPLY
  z.arg.named.shift name $@ && local original_func=$REPLY

  z_t_mock_originals[$func_name]=$original_func
}

# モック元の定義を削除する
#
# $1: 関数名
# REPLY: null
# return: null
#
# example:
#  z.t._state.mock_originals.unset "my_func"
z.t._state.mock_originals.unset() {
  unset "z_t_mock_originals[$1]" 2>/dev/null
}
