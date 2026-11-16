# REPLYに期待値が含まれないことを検証する
#
# $1: 期待する部分文字列
# $skip_unmock?: モック解除を省略するか
# REPLY: null
# return: null
#
# example:
#  REPLY="some long string"
#  z.t.expect.reply.excludes "short"
z.t.expect.reply.excludes() {
  local expect=$1
  local reply=$REPLY
  z.arg.named skip_unmock $@ && local skip_unmock=$REPLY

  z.t.expect.excludes "$reply" "$expect" "skip_unmock=$skip_unmock"
}
