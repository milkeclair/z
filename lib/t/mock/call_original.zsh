# モック内から元の関数を呼び出す
#
# $name: 関数名
# REPLY: null
# return: null
#
# example:
#  z.t.mock.call_original name=my_func
z.t.mock.call_original() {
  z.arg.named name $@ && local name=$REPLY

  z.t.mock name=$name behavior=call_original
}
