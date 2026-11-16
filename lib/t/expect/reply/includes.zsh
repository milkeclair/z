# REPLYに期待値が含まれることを検証する
#
# $1: 期待する部分文字列
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.includes "long"
#  # 結果: 検証成功（失敗件数は増えない）
z.t.expect.reply.includes() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.includes "$reply" "$expect" "skip_unmock=$skip_unmock"
}
