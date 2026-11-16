# モック内から元の関数を呼び出す
#
# $name: 関数名
# REPLY: null
# return: null
#
# example:
#  # my_funcが"hello"を表示する関数の場合
#  z.t.mock.call_original name=my_func
#  my_func
#  # 出力: hello
#  z.t.mock.unmock name=my_func
z.t.mock.call_original() {
  z.arg.named name $@ && local name=$REPLY

  z.t.mock name=$name behavior=call_original
}
